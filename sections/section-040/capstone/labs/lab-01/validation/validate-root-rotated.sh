#!/usr/bin/env bash
# Grader: Confirms OpenBao rotated the password of openbao_admin and still creates credentials.
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

if psql_as openbao_admin openbao-admin-password -c 'SELECT 1' >/dev/null 2>&1; then
  fail "openbao_admin still logs in with the old password: the root credential was not rotated"
fi

CREDS="$(bao_root read -format=json database/creds/inventory-readonly 2>/dev/null)" \
  || fail "OpenBao cannot create credentials for the role inventory-readonly"
DB_USER="$(printf '%s' "$CREDS" | json_query -r '.data.username')"
DB_PASSWORD="$(printf '%s' "$CREDS" | json_query -r '.data.password')"
LEASE_ID="$(printf '%s' "$CREDS" | json_query -r '.lease_id')"
COUNT="$(psql_as "$DB_USER" "$DB_PASSWORD" -c 'SELECT count(*) FROM items' 2>/dev/null)"
bao_root lease revoke -sync "$LEASE_ID" >/dev/null 2>&1 || true
[ "$COUNT" = "3" ] || fail "the new database user $DB_USER cannot read the table items"

pass "the root credential is rotated and new credentials work"
