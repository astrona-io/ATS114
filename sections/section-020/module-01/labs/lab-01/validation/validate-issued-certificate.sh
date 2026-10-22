#!/usr/bin/env bash
# Grader: Confirms a certificate for api.inventory.svc verifies against the full chain and other names are refused.
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

# Copies the root and intermediate CA certificates into /tmp in the tester pod.
# /v1/pki/ca/pem and /v1/pki_int/ca/pem need no token.
fetch_ca_files() {
  in_tester sh -c 'curl -sf http://openbao.openbao:8200/v1/pki/ca/pem > /tmp/root.pem' \
    || fail "cannot download the root CA certificate from /v1/pki/ca/pem"
  in_tester sh -c 'curl -sf http://openbao.openbao:8200/v1/pki_int/ca/pem > /tmp/int.pem' \
    || fail "cannot download the intermediate CA certificate from /v1/pki_int/ca/pem"
  in_tester sh -c 'grep -q "BEGIN CERTIFICATE" /tmp/root.pem' || fail "the pki mount serves no root CA certificate"
  in_tester sh -c 'grep -q "BEGIN CERTIFICATE" /tmp/int.pem' || fail "the pki_int mount serves no CA certificate: the intermediate is not signed and installed"
}

fetch_ca_files
LEAF="$(bao_root write -format=json pki_int/issue/inventory-svc common_name=api.inventory.svc ttl=1h 2>/dev/null \
  | json_query -r '.data.certificate')" || true
printf '%s' "$LEAF" | grep -q 'BEGIN CERTIFICATE' || fail "pki_int/issue/inventory-svc did not issue a certificate for api.inventory.svc"
printf '%s\n' "$LEAF" | in_tester sh -c 'cat > /tmp/leaf.pem'
in_tester openssl verify -CAfile /tmp/root.pem -untrusted /tmp/int.pem /tmp/leaf.pem | grep -q ': OK' \
  || fail "the certificate for api.inventory.svc does not verify against the root and intermediate CA"
if bao_root write pki_int/issue/inventory-svc common_name=www.example.com ttl=1h >/dev/null 2>&1; then
  fail "the role inventory-svc also issued a certificate for www.example.com"
fi
pass "api.inventory.svc verifies against the chain and www.example.com is refused"
