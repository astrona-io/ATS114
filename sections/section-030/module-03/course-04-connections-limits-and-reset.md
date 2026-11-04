# Connections, Limits And Reset

One engine can hold several connections, and each decides which roles may use it. A connection also keeps a pool of connections to the database, which has limits. This part adds a second connection, restricts roles with `allowed_roles`, sets the pool limits, and resets a connection.

## Set up your terminal

The commands in this part need the database engine with the connection `inventory-db`.

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
    allowed_roles="*" \
    connection_url='postgresql://{{username}}:{{password}}@postgres.data:5432/inventory?sslmode=disable' \
    username=openbao_admin \
    password=openbao-admin-password \
    password_authentication=scram-sha-256
```

If the engine and the connection exist, ignore the errors.

## Several connections

A second connection with the same plugin can point at another database, or at the same database with another user. List the connections, and add one that only the role `reporting` may use:

```sh
bao list database/config
bao write database/config/inventory-reporting \
    plugin_name=postgresql-database-plugin \
    allowed_roles="reporting" \
    connection_url='postgresql://{{username}}:{{password}}@postgres.data:5432/inventory?sslmode=disable' \
    username=openbao_admin \
    password=openbao-admin-password \
    password_authentication=scram-sha-256
```

`allowed_roles` is a list of role names, or `*` for every role. A role can name a connection that does not list it, but OpenBao refuses to create a credential for it. Create such a role and then try to read a credential:

```sh
bao write database/roles/not-allowed db_name=inventory-reporting \
    creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}';" default_ttl=5m
```

```sh
bao read database/creds/not-allowed
```

The read is refused with an error that the role is not an allowed role, because `not-allowed` is not in `allowed_roles` of `inventory-reporting`. Restrict a connection to the roles it needs and avoid `*` in production.

## Pool limits

Each connection keeps a pool of database connections. Three settings control it:

| Setting | Meaning |
| --- | --- |
| `max_open_connections` | The most open connections OpenBao keeps to the database for this connection. The default is 4. |
| `max_idle_connections` | How many idle connections stay open. |
| `max_connection_lifetime` | The longest time a connection is reused. |

Set them on the connection, with all other fields, to match what the database allows:

```sh
bao write database/config/inventory-reporting \
    plugin_name=postgresql-database-plugin \
    allowed_roles="reporting" \
    connection_url='postgresql://{{username}}:{{password}}@postgres.data:5432/inventory?sslmode=disable' \
    username=openbao_admin \
    password=openbao-admin-password \
    password_authentication=scram-sha-256 \
    max_open_connections=2 max_idle_connections=1 max_connection_lifetime=5m
bao read database/config/inventory-reporting
```

The read shows the settings under `connection_details`; the password is never shown.

## Reset a connection

If the database restarted, or the pool holds connections that no longer work, close and reopen the connection:

```sh
bao write -f database/reset/inventory-reporting
```

The next request opens a fresh connection. To remove a connection you no longer need, delete it. Delete the roles that use it first, because their credentials would stop working:

```sh
bao delete database/config/inventory-reporting
```

```mermaid
flowchart TB
    E["database/ engine"] --> C1["config/inventory-db (allowed_roles: *)"]
    E --> C2["config/inventory-reporting (allowed_roles: reporting)"]
    C2 --> P["pool: max_open_connections 2"]
```

The diagram shows that one engine holds several connections, and that each connection has its own role list and pool.

You can now manage the connections of an engine. This completes the configuration of the database engine.

## Common pitfalls

> [!WARNING]
> - **Using `allowed_roles="*"` everywhere.** Any role can then use the connection, including a role someone adds later.
> - **Setting `max_open_connections` above what the database allows.** OpenBao then fails when many credentials are created at the same time.
> - **Deleting a connection that roles use.** Their credentials can no longer be created or revoked.

## Your mission: Configure A Database Role With A Username Template

You can now name users, control passwords and write statements with exact rights and working cleanup. The graded lab gives you a connection with default settings and asks you to apply a username template and a password policy, and to add a writer role that can insert and update but not delete.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-114-playground-030-03
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS114.git -c sections/section-030/module-03/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-030/module-03/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-114-lab-030-03
astrona start ats-114-playground-030-03
```
