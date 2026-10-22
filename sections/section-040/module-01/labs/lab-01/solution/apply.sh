#!/usr/bin/env bash
# Reference solution for ats-114-lab-040-01, applied only by `astrona test`.
# `astrona run` never runs this. Taken from solution.md - if one
# changes, change the other.
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
    psql -h 127.0.0.1 -U "$db_user" -d inventory -v ON_ERROR_STOP=1 -tA "$@"
}
pass() { echo "PASS: $*"; exit 0; }
fail() { echo "FAIL: $*"; exit 1; }
# --------------------------------------------------------------------------

for record in record-a record-b record-c; do
  CIPHERTEXT="$(kubectl -n clients get configmap encrypted-records -o jsonpath="{.data.$record}")"
  NEW="$(bao_root write -format=json transit/rewrap/inventory-records ciphertext="$CIPHERTEXT" | json_query -r '.data.ciphertext')"
  kubectl -n clients patch configmap encrypted-records --type merge -p "{\"data\":{\"$record\":\"$NEW\"}}" >/dev/null
done
LATEST="$(bao_root read -format=json transit/keys/inventory-records | json_query -r '.data.latest_version')"
bao_root write transit/keys/inventory-records/config min_decryption_version="$LATEST" >/dev/null
