#!/usr/bin/env bash
# Creates the starting state for ats-114-capstone-020.
#
# Creates the root CA, a role on the root mount by mistake, an intermediate
# CSR that is never signed, a role with the wrong domain, and no URLs on
# pki_int. Records the root CA fingerprint so the graders can tell a
# repaired chain from a new root.
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
bao_root write -format=json pki/root/generate/internal \
  common_name="Inventory Root CA" ttl=87600h >/dev/null
bao_root write pki/config/urls \
  issuing_certificates="http://openbao.localtest.me:8200/v1/pki/ca" \
  crl_distribution_points="http://openbao.localtest.me:8200/v1/pki/crl" >/dev/null

bao_root write pki/roles/inventory-svc allowed_domains=inventory.svc allow_subdomains=true max_ttl=72h >/dev/null
bao_root secrets enable -path=pki_int pki >/dev/null 2>&1 || true
bao_root secrets tune -max-lease-ttl=43800h pki_int >/dev/null
# The CSR is generated and then lost: nobody signed it.
bao_root write -format=json pki_int/intermediate/generate/internal \
  common_name="Inventory Intermediate CA" ttl=43800h >/dev/null
bao_root write pki_int/roles/inventory-svc allowed_domains=inventory.local allow_subdomains=false max_ttl=720h >/dev/null

in_tester sh -c 'curl -sf http://openbao.openbao:8200/v1/pki/ca/pem > /tmp/root.pem'
ROOT_FINGERPRINT="$(in_tester openssl x509 -in /tmp/root.pem -noout -fingerprint -sha256)"
kubectl -n clients create configmap capstone-baseline \
  --from-literal=root-fingerprint="$ROOT_FINGERPRINT" \
  --dry-run=client -o yaml | kubectl apply -f -
echo "[lab] Starting state ready: services cannot get certificates from pki_int."
