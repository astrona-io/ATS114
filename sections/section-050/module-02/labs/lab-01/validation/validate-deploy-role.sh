#!/usr/bin/env bash
# Grader: Confirms the role deploy has the requested type, principals, lifetimes and extension.
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

ROLE="$(bao_root read -format=json ssh/roles/deploy 2>/dev/null)" || fail "the role ssh/roles/deploy does not exist"
field() { printf '%s' "$ROLE" | json_query -r "$1"; }
[ "$(field '.data.key_type')" = "ca" ] || fail "the role key_type is not ca"
[ "$(field '.data.allow_user_certificates')" = "true" ] || fail "the role does not allow user certificates"
USERS="$(field '.data.allowed_users' | tr ',' '\n' | sort | tr '\n' ',')"
[ "$USERS" = "deploy,ops," ] || fail "allowed_users must be exactly deploy and ops"
[ "$(field '.data.default_user')" = "deploy" ] || fail "default_user is not deploy"
case "$(field '.data.ttl')" in 30m|30m0s|0h30m0s|1800) ;; *) fail "ttl is not 30m" ;; esac
case "$(field '.data.max_ttl')" in 4h|4h0m0s|14400) ;; *) fail "max_ttl is not 4h" ;; esac
[ "$(field '.data.default_extensions | has("permit-pty")')" = "true" ] || fail "default_extensions does not contain permit-pty"
pass "the role deploy has the requested settings"
