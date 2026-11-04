#!/usr/bin/env bash
# Creates the starting state for ats-114-lab-020-03.
#
# Enables the PKI mount pki/ with a root CA and the role inventory-svc, issues
# two certificates, and stores the serial number of one of them in the
# ConfigMap compromised-cert in the namespace openbao. No CRL, URL or tidy
# settings are changed from their defaults.
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

bao_root secrets enable pki >/dev/null 2>&1 || true
bao_root secrets tune -max-lease-ttl=87600h pki >/dev/null
bao_root write pki/root/generate/internal common_name="Inventory Root CA" ttl=87600h >/dev/null
bao_root write pki/roles/inventory-svc allowed_domains=inventory.svc allow_subdomains=true max_ttl=72h >/dev/null
bao_root write pki/issue/inventory-svc common_name=healthy.inventory.svc >/dev/null
BAD_SERIAL="$(bao_root write -format=json pki/issue/inventory-svc common_name=leaked.inventory.svc | json_query -r '.data.serial_number')"
kubectl -n openbao create configmap compromised-cert --from-literal=serial="$BAD_SERIAL" \
  --dry-run=client -o yaml | kubectl apply -f - >/dev/null
echo "[lab] Starting state ready: the serial of the leaked certificate is in the ConfigMap compromised-cert."
