#!/usr/bin/env bash
# Grader: Confirms the published signature is valid for the unchanged manifest.
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

MANIFEST="$(kubectl -n clients get configmap release-manifest -o jsonpath='{.data.manifest\.json}' 2>/dev/null)"
BASELINE="$(kubectl -n clients get configmap release-manifest-baseline -o jsonpath='{.data.sha256}' 2>/dev/null)"
[ "$(printf '%s' "$MANIFEST" | in_tester sha256sum | cut -d' ' -f1)" = "$BASELINE" ] || fail "the manifest was changed"
SIGNATURE="$(kubectl -n clients get configmap release-signature -o jsonpath='{.data.signature}' 2>/dev/null)"
[ -n "$SIGNATURE" ] || fail "the ConfigMap release-signature with the key signature is missing"
for variant in "$MANIFEST" "$MANIFEST
"; do
  INPUT="$(printf '%s' "$variant" | base64 | tr -d '\n')"
  VALID="$(bao_root write -format=json transit/verify/release-signing input="$INPUT" signature="$SIGNATURE" 2>/dev/null | json_query -r '.data.valid')"
  [ "$VALID" = "true" ] && pass "the signature in release-signature is valid for the manifest"
done
fail "the signature in release-signature is not valid for the manifest"
