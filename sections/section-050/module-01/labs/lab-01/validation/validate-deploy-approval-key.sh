#!/usr/bin/env bash
# Grader: Confirms the key deploy-approval has the requested settings.
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

KEY="$(bao_root read -format=json totp/keys/deploy-approval 2>/dev/null)" || fail "the TOTP key deploy-approval does not exist"
[ "$(printf '%s' "$KEY" | json_query -r '.data.issuer')" = "Inventory" ] || fail "the issuer is not Inventory"
[ "$(printf '%s' "$KEY" | json_query -r '.data.account_name')" = "release-manager" ] || fail "the account name is not release-manager"
[ "$(printf '%s' "$KEY" | json_query -r '.data.algorithm')" = "SHA256" ] || fail "the algorithm is not SHA256"
[ "$(printf '%s' "$KEY" | json_query -r '.data.digits')" = "8" ] || fail "the key does not use 8 digits"
[ "$(printf '%s' "$KEY" | json_query -r '.data.period')" = "60" ] || fail "the period is not 60 seconds"
pass "deploy-approval uses SHA256, 8 digits and a 60 second period"
