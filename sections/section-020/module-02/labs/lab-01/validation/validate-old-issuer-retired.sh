#!/usr/bin/env bash
# Grader: Confirms inventory-root-1 still exists but can no longer issue certificates.
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

OLD="$(bao_root read -format=json pki/issuer/inventory-root-1 2>/dev/null)" \
  || fail "the issuer inventory-root-1 was deleted; it must stay for old certificates"
USAGE="$(printf '%s' "$OLD" | json_query -r '.data.usage')"
case "$USAGE" in
  *issuing-certificates*) fail "inventory-root-1 can still issue certificates (usage: $USAGE)" ;;
esac
case "$USAGE" in
  *crl-signing*) ;;
  *) fail "inventory-root-1 can no longer sign revocation lists (usage: $USAGE)" ;;
esac
KEY_ID="$(printf '%s' "$OLD" | json_query -r '.data.key_id')"
[ -n "$KEY_ID" ] && [ "$KEY_ID" != "null" ] || fail "the key of inventory-root-1 is gone"
pass "inventory-root-1 is retired but still signs revocation lists"
