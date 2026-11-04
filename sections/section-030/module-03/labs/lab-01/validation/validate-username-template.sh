#!/usr/bin/env bash
# Grader: Confirms credentials of the role writer have names like inv-writer-xxxxxxxx.
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

CRED="$(bao_root read -format=json database/creds/writer 2>/dev/null)" || fail "cannot read a credential from the role writer"
U="$(printf '%s' "$CRED" | json_query -r '.data.username')"
bao_root lease revoke "$(printf '%s' "$CRED" | json_query -r '.lease_id')" >/dev/null 2>&1 || true
printf '%s' "$U" | grep -Eq '^inv-writer-[A-Za-z0-9]{8}$' || fail "the user name '$U' does not match inv-writer- followed by 8 characters"
pass "generated users are named like $U"
