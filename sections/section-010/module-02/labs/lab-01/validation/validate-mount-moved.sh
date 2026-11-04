#!/usr/bin/env bash
# Grader: Confirms the mount apps exists with the original secret and scratch is gone.
set -uo pipefail

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

MOUNTS="$(bao_root read -format=json sys/mounts 2>/dev/null)" || fail "cannot read the mount table"
printf '%s' "$MOUNTS" | json_query -e '.data["apps/"].type == "kv"' >/dev/null 2>&1 || fail "there is no kv mount at apps/"
printf '%s' "$MOUNTS" | json_query -e '.data["scratch/"] == null' >/dev/null 2>&1 || fail "the mount scratch/ still exists"
OWNER="$(bao_root kv get -mount=apps -format=json report/q1 2>/dev/null | json_query -r '.data.data.owner')"
[ "$OWNER" = "finance" ] || fail "the secret report/q1 in apps/ does not hold the original data"
pass "the mount was moved to apps/ and the secret is intact"
