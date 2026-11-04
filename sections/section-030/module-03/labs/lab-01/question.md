# Question

Solve this question on: `terminal`

**Time:** about 30 minutes · **Topic:** Database

## Scenario

The database engine at `database/` has the connection `inventory-db` to PostgreSQL. It allows one role, `writer`, which does not exist yet. The connection uses the default user names and the default password. The DBA team wants users named after their role, a 24-character password and an application role that can read, insert and update rows of the table `items` but cannot delete them.

## Your task

Connect with the lab-only root token (`kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d`) through the port-forward `kubectl -n openbao port-forward svc/openbao 8200:8200`, then:

1. Create the password policy `inventory-password` with a length of 24, at least one lower-case letter, one upper-case letter and one digit.
2. Change the connection `inventory-db` so that generated users are named `inv-<role name>-` followed by 8 random characters, and passwords come from `inventory-password`. The connection keeps its current URL, user and password, and still allows the role `writer`.
3. Create the role `writer` on `inventory-db` with `default_ttl=15m` and `max_ttl=1h`. Its creation statements grant `SELECT`, `INSERT` and `UPDATE` on all tables in the schema `public`. Its revocation statements must take the privileges back and drop the user.

## Constraints

- Do not grant `DELETE`, `ALL PRIVILEGES` or superuser rights.
- Do not change the database `inventory` or the users `postgres` and `openbao_admin`.

## Done when

- A credential from `database/creds/writer` has a user name like `inv-writer-` plus 8 characters and a password of 24 characters.
- The generated user can select, insert and update `items` but cannot delete.
- After the lease is revoked, the user no longer exists in PostgreSQL.
