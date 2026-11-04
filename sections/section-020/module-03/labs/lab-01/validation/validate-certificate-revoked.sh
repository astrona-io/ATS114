#!/usr/bin/env bash
# Grader: Confirms the leaked certificate is revoked and the healthy one is not.
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

SERIAL="$(kubectl -n openbao get configmap compromised-cert -o jsonpath='{.data.serial}' 2>/dev/null)"
[ -n "$SERIAL" ] || fail "the ConfigMap compromised-cert is missing"
REVOKED_AT="$(bao_root read -format=json "pki/cert/$(printf '%s' "$SERIAL" | tr ':' '-')" 2>/dev/null | json_query -r '.data.revocation_time')"
{ [ -n "$REVOKED_AT" ] && [ "$REVOKED_AT" != "null" ] && [ "$REVOKED_AT" != "0" ]; } || fail "the leaked certificate is not revoked"
REVOKED_COUNT=0
for s in $(bao_root list -format=json pki/certs 2>/dev/null | json_query -r '.[]'); do
  t="$(bao_root read -format=json "pki/cert/$s" 2>/dev/null | json_query -r '.data.revocation_time')"
  [ -n "$t" ] && [ "$t" != "null" ] && [ "$t" != "0" ] && REVOKED_COUNT=$((REVOKED_COUNT + 1))
done
[ "$REVOKED_COUNT" -eq 1 ] || fail "$REVOKED_COUNT certificates are revoked; only the leaked certificate may be"
pass "the leaked certificate is revoked and no other certificate is"
