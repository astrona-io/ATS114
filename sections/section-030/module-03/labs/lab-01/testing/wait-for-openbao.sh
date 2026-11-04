#!/usr/bin/env bash
# Runs before the reference solution. Waits until OpenBao is unsealed and
# answers, and until the tester pod (and PostgreSQL, where it exists) is ready.
set -eu

for _ in $(seq 1 90); do
  if kubectl -n clients exec deploy/tester -- \
       curl -sf http://openbao.openbao:8200/v1/sys/health >/dev/null 2>&1; then
    break
  fi
  sleep 2
done
if kubectl get namespace data >/dev/null 2>&1; then
  kubectl -n data rollout status deployment/postgres --timeout=300s
fi
sleep 2
