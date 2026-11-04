#!/usr/bin/env bash
# Reference solution for ats-114-capstone-050, applied only by `astrona test`.
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

printf '%s' '{"key_type":"ca","allow_user_certificates":true,"allowed_users":"ops","default_user":"ops","default_extensions":{"permit-pty":""},"default_critical_options":{"source-address":"10.0.0.0/8"},"ttl":"15m","max_ttl":"1h"}' \
  | bao_root write ssh/roles/ops - >/dev/null
bao_root delete totp/keys/prod-approval >/dev/null
bao_root write totp/keys/prod-approval generate=true exported=false issuer=Inventory account_name=prod \
  algorithm=SHA256 digits=8 period=30 >/dev/null
printf '%s\n' 'path "ssh/sign/ops" {' '  capabilities = ["update"]' '}' | bao_root policy write ssh-signer - >/dev/null
