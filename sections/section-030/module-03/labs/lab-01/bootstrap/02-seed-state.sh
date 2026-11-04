#!/usr/bin/env bash
# Creates the starting state for ats-114-lab-030-03.
#
# Waits for PostgreSQL and enables the database engine with the connection
# inventory-db, which allows the role writer. It sets no username template
# and no password policy, and creates no role.
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
  allowed_roles=writer \
  connection_url='postgresql://{{username}}:{{password}}@postgres.data:5432/inventory?sslmode=disable' \
  username=openbao_admin \
  password=openbao-admin-password \
  password_authentication=scram-sha-256 >/dev/null
echo "[lab] Starting state ready: the connection inventory-db has default settings and no roles."
