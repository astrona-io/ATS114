#!/usr/bin/env bash
# Grader: Confirms the role inventory-svc on pki_int allows names under inventory.svc for at most 72 hours.
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

ROLE="$(bao_root read -format=json pki_int/roles/inventory-svc 2>/dev/null)" || fail "the role inventory-svc does not exist on pki_int"
printf '%s' "$ROLE" | json_query -e '.data.allowed_domains | index("inventory.svc")' >/dev/null \
  || fail "the role inventory-svc does not allow the domain inventory.svc"
[ "$(printf '%s' "$ROLE" | json_query -r '.data.allow_subdomains')" = "true" ] || fail "the role inventory-svc does not allow subdomains"
[ "$(printf '%s' "$ROLE" | json_query -r '.data.max_ttl')" = "259200" ] || fail "the role inventory-svc does not cap certificates at 72h"
if bao_root read pki/roles/inventory-svc >/dev/null 2>&1; then
  fail "the root mount pki/ also has a role inventory-svc: service certificates must come from the intermediate CA only"
fi
pass "the role inventory-svc is correct and exists only on pki_int"
