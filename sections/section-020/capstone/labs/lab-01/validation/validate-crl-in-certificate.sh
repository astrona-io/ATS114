#!/usr/bin/env bash
# Grader: Confirms a certificate from pki_int carries the CRL URL on openbao.localtest.me.
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

LEAF="$(bao_root write -format=json pki_int/issue/inventory-svc common_name=web.inventory.svc ttl=1h 2>/dev/null \
  | json_query -r '.data.certificate')" || true
printf '%s' "$LEAF" | grep -q 'BEGIN CERTIFICATE' || fail "pki_int did not issue a certificate for web.inventory.svc"
printf '%s\n' "$LEAF" | in_tester sh -c 'cat > /tmp/web.pem'
in_tester openssl x509 -in /tmp/web.pem -noout -text | grep -q 'openbao.localtest.me:8200/v1/pki_int/crl' \
  || fail "certificates from pki_int carry no CRL distribution point on openbao.localtest.me"
pass "certificates from pki_int carry the CRL URL"
