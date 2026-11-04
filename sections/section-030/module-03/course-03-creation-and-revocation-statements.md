# Creation And Revocation Statements

The SQL of a role is the only place where the rights of a generated user are set, and the only place that describes how to remove it. A creation statement that grants too much is a security problem. A revocation statement that does not cover the grants leaves the user in the database, because PostgreSQL refuses to drop a role that still has privileges. This part writes a writer role, and cleanup that works.

## Set up your terminal

The commands in this part need the database engine with the connection `inventory-db` that allows all roles.

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

## Placeholders

The statements may use these placeholders, and OpenBao replaces them:

| Placeholder | Where | Meaning |
| --- | --- | --- |
| `{{name}}` | creation and revocation | The generated user name |
| `{{password}}` | creation | The generated password |
| `{{expiration}}` | creation | The time the lease ends, for `VALID UNTIL` |

## Write a role that can insert and update

Save this as `writer-create.sql`. Several statements go in one value, separated by semicolons:

```sql
CREATE ROLE "{{name}}" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO "{{name}}";
```

The role can read, add and change rows, but it cannot delete rows. Save the cleanup as `writer-revoke.sql`:

```sql
REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM "{{name}}";
DROP ROLE IF EXISTS "{{name}}";
```

The `REVOKE` comes first. PostgreSQL refuses `DROP ROLE` with the error `role ... cannot be dropped because some objects depend on it` while the role still holds privileges. Write the role:

```sh
bao write database/roles/writer \
    db_name=inventory-db \
    creation_statements=@writer-create.sql \
    revocation_statements=@writer-revoke.sql \
    default_ttl=15m max_ttl=1h
```

## Check what the user can do

Read a credential and ask the database about its rights. The check runs as the administrator, so you see the rights of the generated user:

```sh
CRED=$(bao read -format=json database/creds/writer)
U=$(echo "$CRED" | jq -r '.data.username')
kubectl -n data exec -i deploy/postgres -- env PGPASSWORD=postgres-admin-password \
    psql -h postgres.data -U postgres -d inventory -tA \
    -c "SELECT has_table_privilege('$U', 'items', 'INSERT'), has_table_privilege('$U', 'items', 'DELETE')"
```

The output is `t|f`: insert is allowed and delete is not. Revoke the lease and check that the user is removed:

```sh
bao lease revoke "$(echo "$CRED" | jq -r '.lease_id')"
kubectl -n data exec -i deploy/postgres -- env PGPASSWORD=postgres-admin-password \
    psql -h postgres.data -U postgres -d inventory -c '\du'
```

## Rollback statements

If a creation statement fails halfway, OpenBao can run `rollback_statements` to remove what was created, for example a role that was made but could not be granted a right. Give them the same form as the revocation, and write them whenever the creation has more than one statement.

```mermaid
sequenceDiagram
    participant O as OpenBao
    participant P as PostgreSQL
    O->>P: creation_statements
    P-->>O: ok
    Note over O,P: lease ends
    O->>P: REVOKE ALL ...
    O->>P: DROP ROLE
```

The diagram shows that the revocation takes the grants back before it drops the user.

You can now write roles with exact rights and cleanup that works. The last part looks at the connection around them.

## Common pitfalls

> [!WARNING]
> - **Granting `ALL PRIVILEGES`.** Grant the exact rights the application uses.
> - **Dropping the role without a `REVOKE`.** PostgreSQL refuses, and the user stays behind after the lease ends.
> - **Hard-coding a name in the statements.** Use `{{name}}` so every generated user is covered.
> - **Granting only on tables that exist today.** `ON ALL TABLES` covers the current tables; later tables need a new grant or default privileges.
