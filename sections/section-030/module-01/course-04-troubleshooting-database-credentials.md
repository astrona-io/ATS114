# Troubleshooting Database Credentials

When an application cannot get a database credential, the cause is almost always one of a few things: the role, the connection, the SQL or the policy. This part breaks each of them on purpose, so you recognize the symptom and know which command shows the cause.

## Set up your terminal

The commands in this part need the database engine at `database/`, the connection `inventory-db` and the role `inventory-readonly`.

<!-- astrona:playground:renew -->

Start the port-forward in a second terminal and leave it running:

```sh
kubectl -n openbao port-forward svc/openbao 8200:8200
```

Point `bao` at the server with the lab-only root token:

```sh
export BAO_ADDR=http://openbao.localtest.me:8200
export BAO_TOKEN=$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)
```

```sh
bao secrets enable database
bao write database/config/inventory-db \
    plugin_name=postgresql-database-plugin \
    allowed_roles="inventory-readonly" \
    connection_url='postgresql://{{username}}:{{password}}@postgres.data:5432/inventory?sslmode=disable' \
    username=openbao_admin \
    password=openbao-admin-password \
    password_authentication=scram-sha-256
bao write database/roles/inventory-readonly \
    db_name=inventory-db \
    creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\";" \
    default_ttl=10m max_ttl=1h
```

If the engine, connection or role exist, ignore the errors.

## A checklist from the outside in

Work from the application toward the database:

1. Does the token have `read` on `database/creds/<role>`? A `permission denied` answer means the policy is wrong, and nothing is wrong with the database.
2. Does the role exist? `bao list database/roles` and `bao read database/roles/<role>` show it.
3. Does the role name a connection that exists, and is the role in that connection's `allowed_roles`? `bao read database/config/inventory-db` shows `allowed_roles`.
4. Can OpenBao reach the database with its own connection user? A failure here shows up when the credential is created.
5. Does the SQL in `creation_statements` run? A failing statement stops the credential.

Test the first step with a token that has no access:

```sh
printf 'path "sys/health" {\n  capabilities = ["read"]\n}\n' | bao policy write nothing -
TOKEN=$(bao token create -policy=nothing -ttl=10m -field=token)
BAO_TOKEN="$TOKEN" bao read database/creds/inventory-readonly
```

The read fails with `permission denied`. The error comes from the policy, not from PostgreSQL.

## A role the connection does not allow

Remove the role from the list of the connection and read a credential:

```sh
bao write database/config/inventory-db \
    plugin_name=postgresql-database-plugin \
    allowed_roles="something-else" \
    connection_url='postgresql://{{username}}:{{password}}@postgres.data:5432/inventory?sslmode=disable' \
    username=openbao_admin \
    password=openbao-admin-password \
    password_authentication=scram-sha-256
bao read database/creds/inventory-readonly
```

The write of the config succeeds, and the read of the credential fails, because the role is not in `allowed_roles` of its connection. Put it back:

```sh
bao write database/config/inventory-db \
    plugin_name=postgresql-database-plugin \
    allowed_roles="inventory-readonly" \
    connection_url='postgresql://{{username}}:{{password}}@postgres.data:5432/inventory?sslmode=disable' \
    username=openbao_admin \
    password=openbao-admin-password \
    password_authentication=scram-sha-256
```

## SQL that fails

Write a role whose statement has a mistake, and read a credential:

```sh
bao write database/roles/broken \
    db_name=inventory-db \
    creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}'; GRANT SELECT ON ALL TABLES IN SCHEMA missing_schema TO \"{{name}}\";" \
    default_ttl=10m max_ttl=1h
bao read database/creds/broken
```

The role is accepted, because OpenBao does not run the SQL when you save it. The read fails with the error that PostgreSQL returned, which names the problem in the statement. A failed read does not give you a credential. A statement that runs several commands can leave a half-created user behind, so check the database after a failure. Remove the test role with `bao delete database/roles/broken`.

To see the SQL error plainly, run the statement yourself as the connection user in `psql`.

## The connection user

The connection user `openbao_admin` needs the right to create and drop roles and to grant the privileges that the statements grant. If an administrator changes its password in PostgreSQL, OpenBao can no longer connect. The symptom is a failed credential read, even though the role and the SQL are correct. Check the connection by writing the configuration again, which verifies the connection unless you pass `verify_connection=false`:

```sh
bao write database/config/inventory-db \
    plugin_name=postgresql-database-plugin \
    allowed_roles="inventory-readonly" \
    connection_url='postgresql://{{username}}:{{password}}@postgres.data:5432/inventory?sslmode=disable' \
    username=openbao_admin \
    password=openbao-admin-password \
    password_authentication=scram-sha-256
```

If it fails, the error says whether the host, the password or the privileges are the cause.

## Credentials that stop working early

An application that fails an hour after it started has usually outlived its lease. Look at the lease of the credential:

```sh
bao lease lookup <LEASE_ID>
```

The `ttl` shows the time left, and `expire_time` shows when the lease ends. If the application never renews, it must ask for a new credential before then. A `max_ttl` on the role is a hard stop: renewing cannot go past it.

```mermaid
flowchart TB
    A["application reads database/creds/role"] --> P{"policy allows read?"}
    P -->|"no"| E1["permission denied"]
    P -->|"yes"| R{"role in allowed_roles?"}
    R -->|"no"| E2["role not allowed"]
    R -->|"yes"| C{"connection user works?"}
    C -->|"no"| E3["connection error"]
    C -->|"yes"| S{"SQL runs?"}
    S -->|"no"| E4["SQL error from PostgreSQL"]
    S -->|"yes"| OK["credential and lease"]
```

The diagram shows the order in which a read can fail, which is also the order in which to check.

You can now find out why a credential was not created. That completes the database basics of this module.

## Common pitfalls

> [!WARNING]
> - **Blaming PostgreSQL for `permission denied`.** That error comes from the OpenBao policy.
> - **Trusting a saved role.** OpenBao does not run the SQL until the first credential is read.
> - **Leaving a broken test role in place.** Delete roles you no longer need.
> - **Changing the password of the connection user in the database only.** Use root rotation or update the connection, so both sides agree.
