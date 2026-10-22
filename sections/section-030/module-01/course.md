# Generate Short-Lived Database Credentials

The inventory application reads from a PostgreSQL table. Today it uses one database user with a password that has not changed in two years, and three other services use the same user. If that password leaks, nobody knows which service leaked it, and changing it breaks all four.

The database secrets engine gives every application instance its own database user, created on request. A dynamic secret is a value OpenBao creates when you ask for it, with a lease: the time it is valid. **When the lease ends or is revoked, OpenBao drops the database user, so a leaked credential stops working on its own.**

This module has three parts. **Dynamic Secrets And The Database Secrets Engine** explains leases and connects OpenBao to PostgreSQL. **Roles, Credentials And Their Leases** writes the SQL that creates read-only users, reads credentials, and renews and revokes their leases. A graded lab follows it. **Rotating The Root Credential And Static Roles** changes OpenBao's own connection password and manages a user that already exists.

## Learning objectives

After this module you can:

- Explain the difference between a static and a dynamic secret, and what a lease holds.
- Connect the database secrets engine to PostgreSQL with a connection URL template.
- Explain why OpenBao should not connect as the database superuser.
- Write a role with creation statements, `default_ttl` and `max_ttl`.
- Read credentials, use them with `psql`, and look up, renew and revoke their lease.
- Revoke every lease under a path with `-prefix`.
- Rotate the root credential and read the credentials of a static role.

## Before you start

You need Kubernetes basics and a terminal with `jq`. You should be able to read a `CREATE ROLE` and a `GRANT` statement in PostgreSQL.

Your playground is a single-node `kind` cluster with **OpenBao v2.7.1** in the namespace `openbao`, already initialized and unsealed, and the `bao` command-line tool on your PATH. **PostgreSQL 17** runs in the namespace `data` as the Deployment `postgres`, with the database `inventory` and a table `items` of three rows. It has two lab-only users: the superuser `postgres` (password `postgres-admin-password`), which OpenBao never gets, and `openbao_admin` (password `openbao-admin-password`), which may create users and grant them access to the tables. You run `psql` inside the PostgreSQL pod, so you need no database client on your machine.

Each part starts with the same short set-up: a port-forward in a second terminal, so your machine reaches OpenBao, and two environment variables, so `bao` knows the address and the token.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
