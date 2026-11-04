#!/usr/bin/env bash
# Creates the starting state for ats-114-lab-040-02.
#
# Enables the Transit engine with no keys, and stores a release manifest in
# the ConfigMap release-manifest (namespace clients) with its SHA-256 in the
# ConfigMap release-manifest-baseline.
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

bao_root secrets enable transit >/dev/null 2>&1 || true
MANIFEST='{"release":"1.4.0","image":"registry.example/inventory:1.4.0","sha256":"9f2c1d0e5a77"}'
kubectl -n clients create configmap release-manifest --from-literal=manifest.json="$MANIFEST" \
  --dry-run=client -o yaml | kubectl apply -f - >/dev/null
BASELINE="$(printf '%s' "$MANIFEST" | in_tester sha256sum | cut -d' ' -f1)"
kubectl -n clients create configmap release-manifest-baseline --from-literal=sha256="$BASELINE" \
  --dry-run=client -o yaml | kubectl apply -f - >/dev/null
echo "[lab] Starting state ready: Transit is enabled, the manifest is in the ConfigMap release-manifest."
