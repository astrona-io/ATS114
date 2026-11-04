#!/usr/bin/env bash
# Seed: an SSH role that is too open, a TOTP key whose secret leaked, and a client public key.
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

bao_root secrets enable ssh >/dev/null 2>&1 || true
bao_root write ssh/config/ca generate_signing_key=true >/dev/null 2>&1 || true
printf '%s' '{"key_type":"ca","allow_user_certificates":true,"allowed_users":"*","default_user":"root","default_extensions":{"permit-pty":""},"ttl":"720h","max_ttl":"720h"}' \
  | bao_root write ssh/roles/ops - >/dev/null
bao_root secrets enable totp >/dev/null 2>&1 || true
bao_root write totp/keys/prod-approval key=MFRGGZDFMZTWQ2LKNNWG23TPOBYXE43U issuer=Inventory account_name=prod >/dev/null
kubectl -n clients create configmap leaked-totp-secret --from-literal=secret=MFRGGZDFMZTWQ2LKNNWG23TPOBYXE43U \
  --dry-run=client -o yaml | kubectl apply -f - >/dev/null
kubectl -n clients create configmap ssh-client-key --from-literal=public_key='ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJreNmlyDtk1TVDUQgN5IY5G/oeRS5Y9JaaJPUK/fwsY lab-client' \
  --dry-run=client -o yaml | kubectl apply -f - >/dev/null
echo "[lab] Starting state ready: role ops is too open and the secret of prod-approval is in the ConfigMap leaked-totp-secret."
