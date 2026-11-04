#!/usr/bin/env bash
# Grader: Confirms the role writer has the right TTLs, can insert and update but not delete, and revokes cleanly.
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

ROLE="$(bao_root read -format=json database/roles/writer 2>/dev/null)" || fail "the role writer does not exist"
[ "$(printf '%s' "$ROLE" | json_query -r '.data.default_ttl')" = "900" ] || fail "default_ttl is not 15m"
[ "$(printf '%s' "$ROLE" | json_query -r '.data.max_ttl')" = "3600" ] || fail "max_ttl is not 1h"
CRED="$(bao_root read -format=json database/creds/writer 2>/dev/null)" || fail "cannot read a credential from the role writer"
U="$(printf '%s' "$CRED" | json_query -r '.data.username')"
LEASE="$(printf '%s' "$CRED" | json_query -r '.lease_id')"
RIGHTS="$(psql_as postgres postgres-admin-password -c "SELECT has_table_privilege('$U','items','SELECT'), has_table_privilege('$U','items','INSERT'), has_table_privilege('$U','items','UPDATE'), has_table_privilege('$U','items','DELETE')")"
bao_root lease revoke "$LEASE" >/dev/null 2>&1 || true
[ "$RIGHTS" = "t|t|t|f" ] || { psql_as postgres postgres-admin-password -c "DROP OWNED BY \"$U\"; DROP ROLE IF EXISTS \"$U\"" >/dev/null 2>&1 || true; fail "the rights on items are '$RIGHTS'; expected select, insert and update but no delete (t|t|t|f)"; }
for _ in $(seq 1 10); do
  [ "$(psql_as postgres postgres-admin-password -c "SELECT count(*) FROM pg_roles WHERE rolname = '$U'")" = "0" ] && pass "the writer role has the right rights and its users are dropped on revoke"
  sleep 2
done
fail "the user $U was not dropped after the lease was revoked; check the revocation statements"
