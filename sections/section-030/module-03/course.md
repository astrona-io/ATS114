# Configuring The Database Engine: Templates, Policies And Statements

A database role that works is not yet a role that is safe to operate. User names should tell an administrator which application owns a user. Passwords should follow the rules of the company, not the default. The SQL that creates and drops a user must grant exactly what the application needs and still be able to clean up. This module covers those settings on the PostgreSQL connection and its roles.

It builds on the connection and role from the dynamic-credentials module. It changes how generated users are named, controls the generated password, writes creation and revocation statements that grant a precise set of rights, and then manages several connections and their limits.

This module has four parts. **Username Templates** shapes the generated names. **Password Policies** controls the length and characters of the password. **Creation And Revocation Statements** gives a role precise rights and makes sure that cleanup succeeds. **Connections, Limits And Reset** manages several connections and the pool; a graded lab follows it.

## Learning objectives

After this module you can:

- Set `username_template` on a connection and predict the names it produces.
- Write a password policy and attach it to a connection.
- Write creation, revocation and rollback statements for a PostgreSQL role.
- Restrict a connection to specific roles with `allowed_roles`.
- Set connection pool limits and reset a connection.

## Before you start

You need a terminal with `jq`. Your playground is a single-node `kind` cluster with **OpenBao v2.7.1** in the namespace `openbao`, already initialized and unsealed, and **PostgreSQL 17** in the namespace `data`. The lab-only root token is in the Kubernetes Secret `openbao-init`. The database engine is not enabled yet; each part enables it in its set-up.

Each part starts with the same short set-up: a port-forward in a second terminal and two environment variables, so `bao` knows the address and the token.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
