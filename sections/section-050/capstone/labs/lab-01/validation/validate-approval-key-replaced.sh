#!/usr/bin/env bash
# Grader: Confirms prod-approval no longer uses the leaked secret and has the requested settings.
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

LEAKED="$(kubectl -n clients get configmap leaked-totp-secret -o jsonpath='{.data.secret}' 2>/dev/null)"
[ -n "$LEAKED" ] || fail "the ConfigMap leaked-totp-secret is missing"
KEY="$(bao_root read -format=json totp/keys/prod-approval 2>/dev/null)" || fail "the TOTP key prod-approval does not exist"
[ "$(printf '%s' "$KEY" | json_query -r '.data.algorithm')" = "SHA256" ] || fail "prod-approval does not use SHA256"
[ "$(printf '%s' "$KEY" | json_query -r '.data.digits')" = "8" ] || fail "prod-approval does not use 8 digits"
[ "$(printf '%s' "$KEY" | json_query -r '.data.period')" = "30" ] || fail "prod-approval does not use a period of 30 seconds"
bao_root write totp/keys/grader-reference key="$LEAKED" issuer=Inventory account_name=prod \
  algorithm=SHA256 digits=8 period=30 >/dev/null 2>&1 || fail "the grader cannot create its reference key"
SAME=0
for _ in 1 2 3; do
  A="$(bao_root read -field=code totp/code/prod-approval 2>/dev/null)"
  B="$(bao_root read -field=code totp/code/grader-reference 2>/dev/null)"
  [ -n "$A" ] && [ "$A" = "$B" ] && SAME=1
done
bao_root delete totp/keys/grader-reference >/dev/null 2>&1 || true
[ "$SAME" = 0 ] || fail "prod-approval still produces the codes of the leaked secret"
pass "prod-approval uses a new secret and the requested settings"
