# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** Leases

## Scenario

The database engine at `database/` has the connection `inventory-db` and the role `inventory-readonly` with a 10-minute default TTL and a 1-hour maximum. Three applications read credentials from it earlier today and are now retired, but their three leases are still active, and their users still exist in PostgreSQL. The new policy is a 5-minute default TTL and a 30-minute maximum. The new application needs one credential, kept alive for about 20 minutes.

## Your task

Connect with the lab-only root token (`kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d`) through the port-forward `kubectl -n openbao port-forward svc/openbao 8200:8200`, then:

1. Revoke every active lease of the role `inventory-readonly`, so that its database users are dropped.
2. Change the role `inventory-readonly` to `default_ttl=5m` and `max_ttl=30m`. Keep `db_name` and the creation statements.
3. Read one new credential from the role and renew its lease to 20 minutes.

## Constraints

- Do not delete the role or the connection.
- Do not revoke the new credential.

## Done when

- None of the three old leases exists and their users are gone from PostgreSQL.
- The role has a default TTL of 5 minutes and a maximum TTL of 30 minutes.
- Exactly one lease is active under `database/creds/inventory-readonly`, and it has been renewed.
