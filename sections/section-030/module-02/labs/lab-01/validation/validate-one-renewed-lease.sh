#!/usr/bin/env bash
# Grader: Confirms exactly one active lease exists and it was renewed beyond the old default.
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

KEYS="$(bao_root list -format=json sys/leases/lookup/database/creds/inventory-readonly 2>/dev/null | json_query -r '.[]?')"
COUNT=0; LEASE=""
for k in $KEYS; do COUNT=$((COUNT + 1)); LEASE="database/creds/inventory-readonly/$k"; done
[ "$COUNT" -eq 1 ] || fail "found $COUNT active leases under inventory-readonly; expected exactly one"
INFO="$(bao_root write -format=json sys/leases/lookup lease_id="$LEASE" 2>/dev/null)" || fail "cannot look up the lease"
TTL="$(printf '%s' "$INFO" | json_query -r '.data.ttl')"
{ [ "$TTL" -gt 360 ] && [ "$TTL" -le 1800 ]; } || fail "the remaining TTL is $TTL seconds; renew the lease to between 6 and 30 minutes"
LAST="$(printf '%s' "$INFO" | json_query -r '.data.last_renewal')"
{ [ -n "$LAST" ] && [ "$LAST" != "null" ]; } || fail "the lease was never renewed"
pass "one active lease, renewed, with $TTL seconds left"
