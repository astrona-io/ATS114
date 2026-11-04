#!/usr/bin/env bash
# Grader: Confirms inventory-root-2 is the default issuer and a new certificate is signed by it.
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

NEW_ID="$(bao_root read -format=json pki/issuer/inventory-root-2 2>/dev/null | json_query -r '.data.issuer_id')" \
  || fail "there is no issuer named inventory-root-2"
[ -n "$NEW_ID" ] && [ "$NEW_ID" != "null" ] || fail "there is no issuer named inventory-root-2"
DEFAULT_ID="$(bao_root read -format=json pki/config/issuers 2>/dev/null | json_query -r '.data.default')"
[ "$DEFAULT_ID" = "$NEW_ID" ] || fail "the default issuer is not inventory-root-2"
ISSUED="$(bao_root write -format=json pki/issue/inventory-svc common_name=grader.inventory.svc ttl=1h 2>/dev/null)" \
  || fail "the role inventory-svc cannot issue a certificate"
ISSUING_CA="$(printf '%s' "$ISSUED" | json_query -r '.data.issuing_ca')"
NEW_CERT="$(bao_root read -format=json pki/issuer/inventory-root-2 | json_query -r '.data.certificate')"
[ "$ISSUING_CA" = "$NEW_CERT" ] || fail "the new certificate is not signed by inventory-root-2"
pass "inventory-root-2 is the default and signs new certificates"
