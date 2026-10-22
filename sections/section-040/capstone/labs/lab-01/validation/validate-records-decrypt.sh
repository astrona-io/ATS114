#!/usr/bin/env bash
# Grader: Confirms every record still decrypts to its original text.
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

baseline() {
  kubectl -n clients get configmap "$1" -o jsonpath="{.data.$2}"
}

for record in record-a record-b; do
  CIPHERTEXT="$(kubectl -n clients get configmap encrypted-records -o jsonpath="{.data.$record}")"
  PLAINTEXT_B64="$(bao_root write -format=json transit/decrypt/inventory-records ciphertext="$CIPHERTEXT" 2>/dev/null \
    | json_query -r '.data.plaintext')" || true
  [ -n "$PLAINTEXT_B64" ] && [ "$PLAINTEXT_B64" != "null" ] || fail "$record does not decrypt with the key inventory-records"
  ACTUAL="$(printf '%s' "$PLAINTEXT_B64" | in_tester sh -c 'base64 -d | sha256sum' | cut -d' ' -f1)"
  [ "$ACTUAL" = "$(baseline records-baseline "$record")" ] || fail "$record decrypts to a different text than before"
done
pass "every record decrypts to its original text"
