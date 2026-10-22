# Dynamic Secrets And The Database Secrets Engine

A static database password has three weaknesses: it lives for years, many people and services share it, and nobody can tell afterwards who used it. OpenBao's answer is a dynamic secret. This part explains what that means and connects the database secrets engine to PostgreSQL, so OpenBao can create users there on request.

## Static secrets, dynamic secrets and leases

A static secret is a value someone stored, such as a password in a KV mount. OpenBao only hands it out; it cannot know whether the value still works, and it cannot take it back. A dynamic secret is a value OpenBao creates at the moment of the request, in a system it controls, such as a new PostgreSQL user.

Every dynamic secret comes with a lease. A lease is a record in OpenBao with an ID, a duration and a flag that says whether it can be renewed. When the duration runs out, or when someone revokes the lease, OpenBao runs the clean-up in the target system: for PostgreSQL, it drops the user.

| | Static secret (KV) | Dynamic secret (database engine) |
| --- | --- | --- |
| Who creates the value | A person or a script | OpenBao, on each request |
| How many consumers share it | Often many | One per request |
| Lifetime | Until someone changes it | The lease, often minutes or hours |
| Can OpenBao take it back | No | Yes, by revoking the lease |

## Set up your terminal and look at PostgreSQL

The commands in this part need the port-forward running in a second terminal.

<!-- astrona:playground:renew -->

Start it and leave it running:

```sh
kubectl -n openbao port-forward svc/openbao 8200:8200
```

Point `bao` at the server with the lab-only root token. A real installation revokes its root token after setup:

```sh
export BAO_ADDR=http://openbao.localtest.me:8200
export BAO_TOKEN=$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)
```

Before OpenBao touches the database, look at it as the database administrator. This runs `psql` inside the PostgreSQL pod and lists the roles, PostgreSQL's name for users:

```sh
kubectl -n data exec -i deploy/postgres -- env PGPASSWORD=postgres-admin-password \
    psql -h 127.0.0.1 -U postgres -d inventory -c '\du'
```

The list shows `postgres`, the superuser, and `openbao_admin`, which has the attribute `Create role` but is not a superuser. `openbao_admin` also holds `SELECT`, `INSERT`, `UPDATE` and `DELETE` on the tables, with the right to pass them on. That is all OpenBao needs to create users and give them access.

## Enable the engine and write the connection

The database secrets engine talks to many databases through plugins; PostgreSQL uses `postgresql-database-plugin`. Enable the engine at its default path `database/`:

```sh
bao secrets enable database
```

A connection tells the engine how to reach one database. Write it as `inventory-db`:

```sh
bao write database/config/inventory-db \
    plugin_name=postgresql-database-plugin \
    allowed_roles="inventory-readonly,inventory-report" \
    connection_url='postgresql://{{username}}:{{password}}@postgres.data:5432/inventory?sslmode=disable' \
    username=openbao_admin \
    password=openbao-admin-password \
    password_authentication=scram-sha-256
```

The fields do the following:

| Field | Meaning |
| --- | --- |
| `plugin_name` | The database plugin to use |
| `allowed_roles` | The roles of this engine that may use this connection |
| `connection_url` | Where the database is; OpenBao fills in `{{username}}` and `{{password}}` itself |
| `username`, `password` | The connection user, also called the root credential of this connection |
| `password_authentication` | How OpenBao hashes passwords it sets: `scram-sha-256`, as PostgreSQL expects by default |

The connection URL uses `postgres.data`, the Service `postgres` in the namespace `data`, because OpenBao runs inside the cluster. `sslmode=disable` is lab-only: a real connection uses TLS.

Read the connection back:

```sh
bao read database/config/inventory-db
```

The response shows the plugin, the allowed roles, the connection URL with the placeholders still in it, and the username. It never shows the password: once written, the root credential can be used by OpenBao but not read back by anyone.

```mermaid
flowchart TB
    A["application"] -->|"read creds"| O["OpenBao database engine"]
    O -->|"connect as openbao_admin"| P["PostgreSQL"]
    O -->|"CREATE ROLE"| P
    O -->|"lease ID, user, password"| A
    A -->|"connect as new user"| P
```

The diagram shows the flow of the next part: the application asks OpenBao, OpenBao creates a user in PostgreSQL as `openbao_admin`, and the application then connects with that new user.

You now know what a dynamic secret and a lease are, and OpenBao can reach PostgreSQL as a user with just enough rights. It cannot create anyone yet, because the connection allows two roles that do not exist. The open question is how a role turns a request into a database user, and how long that user lives.

## Common pitfalls

> [!WARNING]
> - **Connecting as the superuser.** It works, but anyone who can read credentials through OpenBao is then one step away from full control of the database. Give OpenBao a user that can only create roles and grant what they need.
> - **Writing the real password into `connection_url`.** Keep the `{{username}}` and `{{password}}` placeholders, so the root credential can be rotated later.
> - **Using `localhost` in the connection URL.** OpenBao runs in its own pod; `localhost` there is OpenBao itself. Use the Service name.
> - **Forgetting `allowed_roles`.** A role whose name is not in this list cannot use the connection, and every credential request fails.
