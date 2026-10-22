#!/usr/bin/env bash
# Grader: Confirms the four leaked leases are revoked and their database users are gone.
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
    psql -h 127.0.0.1 -U "$db_user" -d inventory -v ON_ERROR_STOP=1 -tA "$@"
}
pass() { echo "PASS: $*"; exit 0; }
fail() { echo "FAIL: $*"; exit 1; }
# --------------------------------------------------------------------------

baseline() {
  kubectl -n clients get configmap "$1" -o jsonpath="{.data.$2}"
}

LEASES="$(baseline capstone-baseline leases)"
USERS="$(baseline capstone-baseline users)"
[ -n "$LEASES" ] || fail "the capstone baseline is missing; restart the capstone"
for lease in $LEASES; do
  if bao_root lease lookup "$lease" >/dev/null 2>&1; then
    fail "the leaked lease $lease still exists"
  fi
done
for db_user in $USERS; do
  FOUND="$(psql_as postgres postgres-admin-password -c "SELECT count(*) FROM pg_roles WHERE rolname = '$db_user'")"
  [ "$FOUND" = "0" ] || fail "the database user $db_user from a leaked lease still exists in PostgreSQL"
done

pass "the leaked leases are revoked and their users are gone"
