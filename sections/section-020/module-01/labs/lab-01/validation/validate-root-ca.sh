#!/usr/bin/env bash
# Grader: Confirms pki holds a self-signed root CA named Inventory Root CA.
set -uo pipefail
# grep -q stops reading at the first match; under pipefail the command
# writing into the pipe then fails with SIGPIPE and a match looks like a
# failure. This wrapper reads all input instead and keeps grep's exit status.
grep() {
  local arg quiet=0 args=()
  for arg in "$@"; do
    case "$arg" in
      --quiet|--silent) quiet=1 ;;
      --*) args+=("$arg") ;;
      -*q*) quiet=1; [ "$arg" = "-q" ] || args+=("${arg//q/}") ;;
      *) args+=("$arg") ;;
    esac
  done
  if [ "$quiet" = 1 ]; then command grep "${args[@]}" >/dev/null; else command grep "$@"; fi
}

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

in_tester sh -c 'curl -sf http://openbao.openbao:8200/v1/pki/ca/pem > /tmp/root.pem' || fail "the mount pki/ serves no CA certificate"
in_tester sh -c 'grep -q "BEGIN CERTIFICATE" /tmp/root.pem' || fail "the mount pki/ serves no CA certificate"
SUBJECT="$(in_tester openssl x509 -in /tmp/root.pem -noout -subject)"
ISSUER="$(in_tester openssl x509 -in /tmp/root.pem -noout -issuer)"
printf '%s' "$SUBJECT" | grep -q 'Inventory Root CA' || fail "the root CA is not named Inventory Root CA ($SUBJECT)"
[ "${SUBJECT#subject=}" = "${ISSUER#issuer=}" ] || fail "the pki CA is not self-signed: it is not a root CA"
pass "pki holds the self-signed root CA Inventory Root CA"
