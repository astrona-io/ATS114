# Question

Solve this question on: `terminal`

**Time:** about 30 minutes · **Topic:** leases

## Scenario

A build job printed four database credentials from OpenBao into a public build log, together with the password of the connection user `openbao_admin`. The role `inventory-readonly` that created them gives every credential a lease of a month, so all four would stay valid for weeks.

## Your task

Connect with the lab-only root token (`kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d`) through the port-forward `kubectl -n openbao port-forward svc/openbao 8200:8200`, then:

1. Change the role `inventory-readonly` so new credentials get a lease of **15 minutes**, at most **1 hour**. Keep its users read-only.
2. Revoke every credential the role has handed out, so their database users are dropped.
3. Make sure the leaked password of `openbao_admin` no longer works, while OpenBao keeps creating credentials.

## Constraints

- Do not disable the database engine or delete the connection `inventory-db`.
- Do not reset the password of `openbao_admin` by hand with the PostgreSQL superuser.

## Done when

- The role `inventory-readonly` has a default TTL of 15 minutes and a maximum TTL of 1 hour.
- None of the four leaked leases exists any more, and none of their database users exists in PostgreSQL.
- `openbao_admin` no longer accepts the password `openbao-admin-password`.
- A new credential from the role can still read `items`.
