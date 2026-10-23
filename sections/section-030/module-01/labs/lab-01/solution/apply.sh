#!/usr/bin/env bash
# Reference solution for ats-114-lab-030-01, applied only by `astrona test`.
# `astrona run` never runs this. Taken from solution.md - if one
# changes, change the other.
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

bao_root secrets enable database >/dev/null 2>&1 || true
bao_root write database/config/inventory-db \
  plugin_name=postgresql-database-plugin \
  allowed_roles=inventory-readonly \
  connection_url='postgresql://{{username}}:{{password}}@postgres.data:5432/inventory?sslmode=disable' \
  username=openbao_admin \
  password=openbao-admin-password \
  password_authentication=scram-sha-256 >/dev/null
printf '%s' 'CREATE ROLE "{{name}}" WITH LOGIN PASSWORD '\''{{password}}'\'' VALID UNTIL '\''{{expiration}}'\''; GRANT SELECT ON ALL TABLES IN SCHEMA public TO "{{name}}";' | bao_root write database/roles/inventory-readonly \
  db_name=inventory-db creation_statements=- default_ttl=10m max_ttl=1h >/dev/null
