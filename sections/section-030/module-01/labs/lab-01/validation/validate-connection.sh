#!/usr/bin/env bash
# Grader: Confirms the connection inventory-db uses the PostgreSQL plugin as openbao_admin and allows the role inventory-readonly.
set -uo pipefail

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

CONFIG="$(bao_root read -format=json database/config/inventory-db 2>/dev/null)" || fail "the connection database/config/inventory-db does not exist"
[ "$(printf '%s' "$CONFIG" | json_query -r '.data.plugin_name')" = "postgresql-database-plugin" ] || fail "inventory-db does not use postgresql-database-plugin"
DB_ADMIN="$(printf '%s' "$CONFIG" | json_query -r '.data.connection_details.username')"
[ "$DB_ADMIN" = "openbao_admin" ] || fail "inventory-db connects as '$DB_ADMIN'; OpenBao must connect as openbao_admin, never as the superuser"
printf '%s' "$CONFIG" | json_query -e '.data.allowed_roles | index("inventory-readonly")' >/dev/null \
  || fail "inventory-db does not allow the role inventory-readonly"
pass "inventory-db is configured correctly"
