#!/usr/bin/env bash
# Grader: Confirms the policy release-verifier can verify but not sign or read the key.
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

bao_root policy read release-verifier >/dev/null 2>&1 || fail "the policy release-verifier does not exist"
TOKEN="$(bao_root token create -policy=release-verifier -ttl=10m -field=token 2>/dev/null)" || fail "cannot create a token with release-verifier"
with_token() { kubectl -n openbao exec -i openbao-0 -- env BAO_ADDR=http://127.0.0.1:8200 BAO_TOKEN="$TOKEN" bao "$@"; }
INPUT="$(printf '%s' 'grader' | base64)"
SIG="$(bao_root write -field=signature transit/sign/release-signing input="$INPUT" 2>/dev/null)"
[ "$(with_token write -format=json transit/verify/release-signing input="$INPUT" signature="$SIG" 2>/dev/null | json_query -r '.data.valid')" = "true" ] \
  || fail "a token with release-verifier cannot verify"
if with_token write transit/sign/release-signing input="$INPUT" >/dev/null 2>&1; then
  fail "a token with release-verifier can sign"
fi
if with_token read transit/keys/release-signing >/dev/null 2>&1; then
  fail "a token with release-verifier can read the key settings"
fi
pass "release-verifier can verify and nothing else"
