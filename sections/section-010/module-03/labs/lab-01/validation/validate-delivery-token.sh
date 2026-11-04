#!/usr/bin/env bash
# Grader: Confirms the ConfigMap delivery holds an unused wrapping token for secret/inventory/api that lives 10 minutes.
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

TOKEN="$(kubectl -n clients get configmap delivery -o jsonpath='{.data.token}' 2>/dev/null)"
[ -n "$TOKEN" ] || fail "the ConfigMap delivery does not exist or has no key token"
LOOKUP="$(bao_root write -format=json sys/wrapping/lookup token="$TOKEN" 2>/dev/null)" \
  || fail "the token in delivery is not a valid wrapping token (it may already be unwrapped or expired)"
[ "$(printf '%s' "$LOOKUP" | json_query -r '.data.creation_path')" = "secret/data/inventory/api" ] \
  || fail "the wrapping token was not made from secret/data/inventory/api"
[ "$(printf '%s' "$LOOKUP" | json_query -r '.data.creation_ttl')" = "600" ] \
  || fail "the wrapping token does not live 10 minutes (600 seconds)"
pass "delivery holds an unused wrapping token for secret/inventory/api with a TTL of 10 minutes"
