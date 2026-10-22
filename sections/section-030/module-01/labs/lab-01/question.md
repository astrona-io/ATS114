# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** database engine and leases

## Scenario

The inventory application reads the table `items` in the PostgreSQL database `inventory`. Today it logs in with a shared password that never changes. The team wants every application instance to get its own read-only database user from OpenBao, valid for a few minutes at a time.

PostgreSQL runs in the namespace `data` (Service `postgres`, port `5432`). It has two lab-only users: the superuser `postgres` (password `postgres-admin-password`) and `openbao_admin` (password `openbao-admin-password`), which may create users and grant table access.

## Your task

Connect with the lab-only root token (`kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d`) through the port-forward `kubectl -n openbao port-forward svc/openbao 8200:8200`, then:

1. Enable the database secrets engine at `database/`.
2. Create a connection `inventory-db` to the database `inventory` with the PostgreSQL plugin, connecting as `openbao_admin`.
3. Create a role `inventory-readonly` whose users can read every table in the schema `public` and nothing else. New credentials get a lease of **10 minutes**, at most **1 hour**.

## Constraints

- OpenBao must never connect as the superuser `postgres`.
- The users the role creates must not be able to change data.

## Done when

- `database/config/inventory-db` uses `postgresql-database-plugin`, connects as `openbao_admin` and allows the role `inventory-readonly`.
- The role `inventory-readonly` has a default TTL of 10 minutes and a maximum TTL of 1 hour.
- A new credential can read the three rows of `items`, cannot insert into it, and its user no longer exists in PostgreSQL after its lease is revoked.
