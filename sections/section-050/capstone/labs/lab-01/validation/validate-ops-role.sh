#!/usr/bin/env bash
# Grader: Confirms the role ops is restricted to the principal ops, short lifetimes and a source address.
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

ROLE="$(bao_root read -format=json ssh/roles/ops 2>/dev/null)" || fail "the role ssh/roles/ops does not exist"
field() { printf '%s' "$ROLE" | json_query -r "$1"; }
[ "$(field '.data.key_type')" = "ca" ] || fail "the role key_type is not ca"
[ "$(field '.data.allowed_users')" = "ops" ] || fail "allowed_users must be exactly ops"
[ "$(field '.data.default_user')" = "ops" ] || fail "default_user is not ops"
case "$(field '.data.ttl')" in 15m|15m0s|0h15m0s|900) ;; *) fail "ttl is not 15m" ;; esac
case "$(field '.data.max_ttl')" in 1h|1h0m0s|3600) ;; *) fail "max_ttl is not 1h" ;; esac
[ "$(field '.data.default_critical_options["source-address"]')" = "10.0.0.0/8" ] || fail "default_critical_options does not set source-address to 10.0.0.0/8"
pass "the role ops is restricted"
