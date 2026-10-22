#!/usr/bin/env bash
# Grader: Confirms the current version of inventory/db holds the data of version 2 without the leaked field.
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
    psql -h 127.0.0.1 -U "$db_user" -d inventory -v ON_ERROR_STOP=1 -tA "$@"
}
pass() { echo "PASS: $*"; exit 0; }
fail() { echo "FAIL: $*"; exit 1; }
# --------------------------------------------------------------------------

read_current() {
  bao_root kv get -format=json -mount=secret "$1" 2>/dev/null
}
read_metadata() {
  bao_root kv metadata get -format=json -mount=secret "$1" 2>/dev/null
}

CURRENT="$(read_current inventory/db)" || fail "cannot read the current version of secret/inventory/db"
PASSWORD="$(printf '%s' "$CURRENT" | json_query -r '.data.data.password')"
HAS_DUMP="$(printf '%s' "$CURRENT" | json_query -r '.data.data | has("debug_dump")')"
VERSION="$(printf '%s' "$CURRENT" | json_query -r '.data.metadata.version')"
[ "$HAS_DUMP" = "false" ] || fail "the current version of inventory/db still has the field debug_dump"
[ "$PASSWORD" = "Inv-2026-b" ] || fail "the current version of inventory/db does not hold the password of version 2"
[ "$VERSION" -ge 4 ] 2>/dev/null || fail "the current version is $VERSION; restore version 2 as a new version"
pass "inventory/db version $VERSION is clean"
