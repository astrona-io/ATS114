#!/usr/bin/env bash
# Grader: Confirms the role inventory-readonly has default_ttl 5m and max_ttl 30m.
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

ROLE="$(bao_root read -format=json database/roles/inventory-readonly 2>/dev/null)" || fail "cannot read the role inventory-readonly"
[ "$(printf '%s' "$ROLE" | json_query -r '.data.default_ttl')" = "300" ] || fail "default_ttl is not 5m"
[ "$(printf '%s' "$ROLE" | json_query -r '.data.max_ttl')" = "1800" ] || fail "max_ttl is not 30m"
[ "$(printf '%s' "$ROLE" | json_query -r '.data.db_name')" = "inventory-db" ] || fail "the role no longer uses inventory-db"
pass "the role has default_ttl 5m and max_ttl 30m"
