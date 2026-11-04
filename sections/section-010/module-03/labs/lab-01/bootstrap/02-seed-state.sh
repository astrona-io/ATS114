#!/usr/bin/env bash
# Creates the starting state for ats-114-lab-010-03.
#
# Enables the KV version 2 mount secret/ with the secret inventory/api. A
# partner key is wrapped for one hour, the only copy is the wrapping token in
# the ConfigMap received, and the stored secret is deleted.
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

bao_root secrets enable -path=secret kv-v2 >/dev/null 2>&1 || true
bao_root kv put -mount=secret inventory/api api-key=abc-123-def >/dev/null
bao_root kv put -mount=secret inventory/partner-source api-key=partner-abc-123 >/dev/null
RECEIVED_TOKEN="$(bao_root read -wrap-ttl=1h -field=wrapping_token secret/data/inventory/partner-source)"
bao_root kv metadata delete -mount=secret inventory/partner-source >/dev/null
kubectl -n clients create configmap received --from-literal=token="$RECEIVED_TOKEN" \
  --dry-run=client -o yaml | kubectl apply -f -
echo "[lab] Starting state ready: the partner key exists only inside the wrapping token in the ConfigMap received."
