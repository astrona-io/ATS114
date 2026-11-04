#!/usr/bin/env bash
# Grader: Confirms partner-vpn was imported from the partner secret by comparing its codes with a reference key.
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

SECRET="$(kubectl -n clients get configmap partner-totp-secret -o jsonpath='{.data.secret}' 2>/dev/null)"
[ -n "$SECRET" ] || fail "the ConfigMap partner-totp-secret is missing"
KEY="$(bao_root read -format=json totp/keys/partner-vpn 2>/dev/null)" || fail "the TOTP key partner-vpn does not exist"
[ "$(printf '%s' "$KEY" | json_query -r '.data.issuer')" = "Partner" ] || fail "the issuer of partner-vpn is not Partner"
[ "$(printf '%s' "$KEY" | json_query -r '.data.account_name')" = "ops@partner.example" ] || fail "the account name of partner-vpn is not ops@partner.example"
bao_root write totp/keys/grader-reference key="$SECRET" issuer=Partner account_name=ops@partner.example >/dev/null 2>&1 \
  || fail "the grader cannot create its reference key"
MATCH=0
for _ in 1 2 3; do
  A="$(bao_root read -field=code totp/code/partner-vpn 2>/dev/null)"
  B="$(bao_root read -field=code totp/code/grader-reference 2>/dev/null)"
  [ -n "$A" ] && [ "$A" = "$B" ] && { MATCH=1; break; }
  sleep 2
done
bao_root delete totp/keys/grader-reference >/dev/null 2>&1 || true
[ "$MATCH" = 1 ] || fail "partner-vpn does not produce the codes of the partner secret"
pass "partner-vpn produces the same codes as the partner secret"
