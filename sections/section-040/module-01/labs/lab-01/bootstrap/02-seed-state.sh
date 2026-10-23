#!/usr/bin/env bash
# Creates the starting state for ats-114-lab-040-01.
#
# Enables Transit, creates the key inventory-records and encrypts three
# records with key versions 1, 1 and 2 before a last rotation to version 3.
# The ciphertexts go into the ConfigMap encrypted-records (the application's
# stored data) and their SHA-256 hashes into records-baseline.
set -euo pipefail

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

# encrypt_record TEXT prints the Transit ciphertext of TEXT.
encrypt_record() {
  bao_root write -format=json transit/encrypt/inventory-records \
    plaintext="$(printf '%s' "$1" | base64 | tr -d '\n')" | json_query -r '.data.ciphertext'
}
# hash_text TEXT prints the SHA-256 of TEXT, computed in the tester pod.
hash_text() { printf '%s' "$1" | in_tester sha256sum | cut -d' ' -f1; }
bao_root secrets enable transit >/dev/null 2>&1 || true
bao_root write -f transit/keys/inventory-records >/dev/null
RECORD_A="$(encrypt_record 'order-1001: 40 bolts for dock 3')"
RECORD_A_HASH="$(hash_text 'order-1001: 40 bolts for dock 3')"
RECORD_B="$(encrypt_record 'order-1002: 12 washers for dock 1')"
RECORD_B_HASH="$(hash_text 'order-1002: 12 washers for dock 1')"
bao_root write -f transit/keys/inventory-records/rotate >/dev/null
RECORD_C="$(encrypt_record 'order-1003: 300 nuts for dock 2')"
RECORD_C_HASH="$(hash_text 'order-1003: 300 nuts for dock 2')"
bao_root write -f transit/keys/inventory-records/rotate >/dev/null
kubectl -n clients create configmap encrypted-records \
  --from-literal=record-a="$RECORD_A" \
  --from-literal=record-b="$RECORD_B" \
  --from-literal=record-c="$RECORD_C" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl -n clients create configmap records-baseline \
  --from-literal=record-a="$RECORD_A_HASH" \
  --from-literal=record-b="$RECORD_B_HASH" \
  --from-literal=record-c="$RECORD_C_HASH" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "[lab] Starting state ready: the stored records use key versions 1 and 2; the newest is 3."
