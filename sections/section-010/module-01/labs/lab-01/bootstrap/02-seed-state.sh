#!/usr/bin/env bash
# Creates the starting state for ats-114-lab-010-01.
#
# Enables KV version 2 at secret/, writes three versions of inventory/db
# (the third one is a bad write) and soft-deletes inventory/api. Records the
# creation times of version 1 so the graders can tell recovered secrets from
# re-created ones.
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

bao_root secrets enable -path=secret kv-v2 >/dev/null 2>&1 || true
bao_root kv put -mount=secret inventory/db username=inventory password=Inv-2026-a >/dev/null
bao_root kv put -mount=secret inventory/db username=inventory password=Inv-2026-b >/dev/null
bao_root kv put -mount=secret inventory/db username=inventory password=CHANGEME >/dev/null
bao_root kv put -mount=secret inventory/api token=api-token-7731 >/dev/null
bao_root kv delete -mount=secret inventory/api >/dev/null

DB_V1_CREATED="$(bao_root kv metadata get -format=json -mount=secret inventory/db | json_query -r '.data.versions["1"].created_time')"
API_V1_CREATED="$(bao_root kv metadata get -format=json -mount=secret inventory/api | json_query -r '.data.versions["1"].created_time')"
kubectl -n clients create configmap lab-baseline \
  --from-literal=db-v1-created="$DB_V1_CREATED" \
  --from-literal=api-v1-created="$API_V1_CREATED" \
  --dry-run=client -o yaml | kubectl apply -f -
echo "[lab] Starting state ready: inventory/db has a bad current version and inventory/api is deleted."
