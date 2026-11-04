# Listing And Revoking Leases

An incident usually does not start with a lease ID. A credential leaked, an application created too many users, or a role must be shut down. This part lists the leases of a role, revokes one, revokes all leases of a role, and shows what the force option is for.

## Set up your terminal

The commands in this part need the database engine with the connection `inventory-db` and the role `inventory-readonly`.

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

## List the leases of a role

Create three credentials, then list the leases under the role. The path is `sys/leases/lookup/` followed by the prefix:

```sh
for i in 1 2 3; do bao read -format=json database/creds/inventory-readonly | jq -r '.lease_id'; done
bao list sys/leases/lookup/database/creds/inventory-readonly
```

The list shows the random part of each lease ID. The full lease ID is the prefix, a slash and that part. Listing needs a token with the `list` capability on `sys/leases/lookup/` and the prefix. The root token has it; an application token normally does not.

## Revoke one lease

```sh
FIRST=$(bao list -format=json sys/leases/lookup/database/creds/inventory-readonly | jq -r '.[0]')
bao lease revoke database/creds/inventory-readonly/"$FIRST"
```

OpenBao revokes the lease and runs the role's revocation statements, so the user is dropped in PostgreSQL. Check the list again after a few seconds to see that the lease is gone.

## Revoke by prefix

Revoking everything under a prefix is the tool for an incident. It ends every lease whose ID begins with the prefix:

```sh
bao lease revoke -prefix database/creds/inventory-readonly
bao list sys/leases/lookup/database/creds/inventory-readonly
```

The list now fails with `No value found`, because no lease is left. All generated users are dropped. A prefix of `database/creds/` would revoke the leases of every role, and `database/` those of the whole engine. Use the longest prefix that covers the incident.

## When a revocation fails

If the database is down, OpenBao cannot run the revocation statements. The lease then stays and OpenBao retries. To remove the lease entry anyway, for example after the database was deleted, use force:

```sh
bao lease revoke -force -prefix database/creds/inventory-readonly
```

`-force` removes the lease entries even if the revocation statements fail, so users that still exist in the database stay behind and must be dropped by hand. Use it only when you know that the database work cannot succeed, and check `\du` afterwards.

```mermaid
flowchart TB
    L["lease revoke"] -->|"run revocation statements"| OK{"success?"}
    OK -->|"yes"| G["lease removed, user dropped"]
    OK -->|"no"| R["retry later"]
    F["lease revoke -force"] -->|"skip errors"| G2["lease removed, user may remain"]
```

The diagram shows that a normal revoke waits for the database, while force removes the lease whatever the database says.

You can now find and end leases one by one and in bulk. The last part connects leases to the tokens that created them.

## Common pitfalls

> [!WARNING]
> - **Using too short a prefix.** `database/` revokes every credential of every application.
> - **Using `-force` as the first choice.** It hides a database problem and leaves users behind.
> - **Forgetting that the prefix ends with a slash.** `-prefix database/creds/inventory-readonly` matches the role and any role whose name starts the same way. Add a trailing slash when you mean only one role.
