#!/usr/bin/env bash
# Reference solution for ats-114-lab-050-01, applied only by `astrona test`.
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
    psql -h postgres.data -U "$db_user" -d inventory -v ON_ERROR_STOP=1 -tA "$@"
}
pass() { echo "PASS: $*"; exit 0; }
fail() { echo "FAIL: $*"; exit 1; }
# --------------------------------------------------------------------------

bao_root secrets enable totp >/dev/null 2>&1 || true
bao_root write totp/keys/deploy-approval generate=true exported=false issuer=Inventory \
  account_name=release-manager period=60 digits=8 algorithm=SHA256 >/dev/null
SECRET="$(kubectl -n clients get configmap partner-totp-secret -o jsonpath='{.data.secret}')"
bao_root write totp/keys/partner-vpn key="$SECRET" issuer=Partner account_name=ops@partner.example >/dev/null
printf '%s\n' 'path "totp/code/deploy-approval" {' '  capabilities = ["update"]' '}' | bao_root policy write totp-validator - >/dev/null
