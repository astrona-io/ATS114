#!/usr/bin/env bash
# Creates the starting state for ats-114-capstone-010.
#
# Writes inventory/db with a leaked field in its current version and
# inventory/payments without check-and-set. Records creation times so the
# graders can tell repaired secrets from re-created ones.
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
bao_root kv put -mount=secret inventory/db username=inventory password=Inv-2026-b debug_dump=lab-fake-dump-7f3a9c >/dev/null
bao_root kv put -mount=secret inventory/payments api_key=pay-live-1234 >/dev/null

DB_V1_CREATED="$(bao_root kv metadata get -format=json -mount=secret inventory/db | json_query -r '.data.versions["1"].created_time')"
PAY_V1_CREATED="$(bao_root kv metadata get -format=json -mount=secret inventory/payments | json_query -r '.data.versions["1"].created_time')"
kubectl -n clients create configmap capstone-baseline \
  --from-literal=db-v1-created="$DB_V1_CREATED" \
  --from-literal=payments-v1-created="$PAY_V1_CREATED" \
  --dry-run=client -o yaml | kubectl apply -f -
echo "[lab] Starting state ready."
