#!/usr/bin/env bash
# Grader: Signs the client key through the role. The principal deploy must work and root must be refused.
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

PUB="$(kubectl -n clients get configmap ssh-client-key -o jsonpath='{.data.public_key}' 2>/dev/null)"
[ -n "$PUB" ] || fail "the ConfigMap ssh-client-key is missing"
SIGNED="$(bao_root write -field=signed_key ssh/sign/deploy public_key="$PUB" valid_principals=deploy 2>/dev/null)"
[ -n "$SIGNED" ] || fail "signing the client key for the principal deploy failed"
case "$SIGNED" in ssh-*-cert-v01@openssh.com*) ;; *) fail "the signed key is not an SSH certificate" ;; esac
if bao_root write -field=signed_key ssh/sign/deploy public_key="$PUB" valid_principals=root >/dev/null 2>&1; then
  fail "the role signed a certificate for the principal root"
fi
pass "the role signs for deploy and refuses root"
