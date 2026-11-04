# Username Templates

By default OpenBao names a generated PostgreSQL user `v-` followed by the token display name, the role name, random letters and the creation time. That name is long, and it is cut to fit the database. A DBA looking at a list of users wants a name that says which application it belongs to. The `username_template` of a connection decides the name. This part sets a template and reads the names it produces.

## Set up your terminal

The commands in this part need the database engine at `database/` with the connection `inventory-db` and a read-only role.

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

```sh
bao write database/roles/inventory-readonly \
    db_name=inventory-db \
    creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\";" \
    default_ttl=10m max_ttl=1h
```

If the engine, connection or role exist, ignore the errors.

## The default name

Read a credential and look at the user name:

```sh
bao read -field=username database/creds/inventory-readonly
```

The name starts with `v-`, and then holds the display name of the token (`root` for the root token), the role name, a random string and a Unix time. A different token gives a different display name, so the name depends on who asked.

## Set a template

A username template is written in the Go template language. The values and functions you can use are the following:

| Part | Meaning |
| --- | --- |
| `{{.DisplayName}}` | The display name of the token that asked |
| `{{.RoleName}}` | The name of the role |
| `{{random 8}}` | Eight random letters and digits |
| `{{unix_time}}` | The current Unix time |
| `{{truncate 10}}` | Used after a value, as in `{{.RoleName | truncate 10}}`, to cut it to 10 characters |

The template belongs to the **connection**, so it applies to every role that uses it. Write all connection fields again with the template added, so that no setting is lost:

```sh
bao write database/config/inventory-db \
    plugin_name=postgresql-database-plugin \
    allowed_roles="*" \
    connection_url='postgresql://{{username}}:{{password}}@postgres.data:5432/inventory?sslmode=disable' \
    username=openbao_admin \
    password=openbao-admin-password \
    password_authentication=scram-sha-256 \
    username_template='inv-{{.RoleName}}-{{random 8}}'
bao read -field=username database/creds/inventory-readonly
```

The new name looks like `inv-inventory-readonly-` followed by eight characters. Users that already exist keep their old names, because the template is used only when a credential is created.

## Keep the name valid

PostgreSQL limits a role name to 63 characters. If the template can produce a longer name, the creation fails or the database cuts it. Use `truncate` on long parts, and keep the random part long enough to avoid collisions; eight characters of letters and digits are enough for a role that creates a few users per hour.

```mermaid
flowchart LR
    T["username_template"] --> N["inv-inventory-readonly-aB3dE9xZ"]
    R["role name"] --> T
    X["random 8"] --> T
```

The diagram shows that the connection template combines the role name with random characters to build each user name.

You can now name generated users. The password of a user has its own setting, and the next part covers it.

## Common pitfalls

> [!WARNING]
> - **Writing only `username_template` to the connection.** Send every field in the same write, so that no setting is lost, and read the connection back.
> - **Using a template that can repeat.** A template with no `random` part gives the same name twice for the same role, and the second creation fails.
> - **Expecting old users to be renamed.** Only new credentials use the new template.
