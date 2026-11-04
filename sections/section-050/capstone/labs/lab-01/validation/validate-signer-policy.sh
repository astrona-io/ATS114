#!/usr/bin/env bash
# Grader: Confirms ssh-signer can sign through the role ops and cannot read the CA settings or use other roles.
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
bao_root policy read ssh-signer >/dev/null 2>&1 || fail "the policy ssh-signer does not exist"
TOKEN="$(bao_root token create -policy=ssh-signer -ttl=10m -field=token 2>/dev/null)" || fail "cannot create a token with ssh-signer"
with_token() { kubectl -n openbao exec -i openbao-0 -- env BAO_ADDR=http://127.0.0.1:8200 BAO_TOKEN="$TOKEN" bao "$@"; }
SIGNED="$(with_token write -field=signed_key ssh/sign/ops public_key="$PUB" valid_principals=ops 2>/dev/null)"
[ -n "$SIGNED" ] || fail "a token with ssh-signer cannot sign through the role ops"
if with_token read ssh/config/ca >/dev/null 2>&1; then
  fail "a token with ssh-signer can read ssh/config/ca"
fi
if with_token write ssh/roles/other key_type=ca allow_user_certificates=true allowed_users=ops >/dev/null 2>&1; then
  bao_root delete ssh/roles/other >/dev/null 2>&1 || true
  fail "a token with ssh-signer can write roles"
fi
if with_token write ssh/sign/other public_key="$PUB" valid_principals=ops >/dev/null 2>&1; then
  fail "a token with ssh-signer can sign through other roles"
fi
pass "ssh-signer signs through the role ops and does nothing else"
