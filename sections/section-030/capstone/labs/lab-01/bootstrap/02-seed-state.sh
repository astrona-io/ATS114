#!/usr/bin/env bash
# Creates the starting state for ats-114-capstone-030.
#
# Configures inventory-db and a role with month-long leases, then creates four
# credentials that are treated as leaked. Records their lease IDs and user
# names for the graders.
set -euo pipefail

# --- shared helpers (the same block in every ATS114 environment) ---------
# ROOT_TOKEN is the lab-only root token from the Secret openbao-init. A real
# installation never keeps it in a Kubernetes Secret.
ROOT_TOKEN="$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)"
# bao_root runs the bao CLI inside the OpenBao pod with the root token.
bao_root() { kubectl -n openbao exec -i openbao-0 -- env BAO_ADDR=http://127.0.0.1:8200 BAO_TOKEN="$ROOT_TOKEN" bao "$@"; }
# json_query runs jq inside the tester pod, so the host needs no jq.
json_query() { kubectl -n clients exec -i deploy/tester -- jq "$@"; }
# in_tester runs a command inside the tester pod.
in_tester() { kubectl -n clients exec -i deploy/tester -- "$@"; }
# psql_as USER PASSWORD ARGS... runs psql inside the PostgreSQL pod.
psql_as() {
  local db_user="$1" db_password="$2"; shift 2
  kubectl -n data exec -i deploy/postgres -- env PGPASSWORD="$db_password" \
    psql -h postgres.data -U "$db_user" -d inventory -v ON_ERROR_STOP=1 -tA "$@"
}
pass() { echo "PASS: $*"; exit 0; }
fail() { echo "FAIL: $*"; exit 1; }
# --------------------------------------------------------------------------

for _ in $(seq 1 60); do
  [ "$(psql_as postgres postgres-admin-password -c "SELECT count(*) FROM pg_roles WHERE rolname = 'openbao_admin'" 2>/dev/null)" = "1" ] && break
  sleep 2
done

bao_root secrets enable database >/dev/null 2>&1 || true
bao_root write database/config/inventory-db \
  plugin_name=postgresql-database-plugin \
  allowed_roles=inventory-readonly \
  connection_url='postgresql://{{username}}:{{password}}@postgres.data:5432/inventory?sslmode=disable' \
  username=openbao_admin \
  password=openbao-admin-password \
  password_authentication=scram-sha-256 >/dev/null
printf '%s' 'CREATE ROLE "{{name}}" WITH LOGIN PASSWORD '\''{{password}}'\'' VALID UNTIL '\''{{expiration}}'\''; GRANT SELECT ON ALL TABLES IN SCHEMA public TO "{{name}}";' | bao_root write database/roles/inventory-readonly \
  db_name=inventory-db creation_statements=- default_ttl=768h max_ttl=768h >/dev/null
LEASES=""
USERS=""
for _ in 1 2 3 4; do
  CREDS="$(bao_root read -format=json database/creds/inventory-readonly)"
  LEASES="$LEASES $(printf '%s' "$CREDS" | json_query -r '.lease_id')"
  USERS="$USERS $(printf '%s' "$CREDS" | json_query -r '.data.username')"
done
kubectl -n clients create configmap capstone-baseline \
  --from-literal=leases="${LEASES# }" --from-literal=users="${USERS# }" \
  --dry-run=client -o yaml | kubectl apply -f -
echo "[lab] Starting state ready: four leaked credentials are valid for a month."
