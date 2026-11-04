# Anatomy Of A Lease

A lease is created each time OpenBao returns a secret that it can end later. This part creates the engine, a role and a credential, and then reads the lease from every angle: in the response of the read, with `bao lease lookup`, and through the system API.

## Set up your terminal

The commands in this part need the database engine at `database/`, the connection `inventory-db`, and the role `inventory-readonly` with a 10-minute default and a 1-hour maximum.

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

## Read a credential

Reading from `database/creds/<role>` creates a database user and a lease. Keep the full response:

```sh
bao read -format=json database/creds/inventory-readonly > creds.json
jq '{lease_id, lease_duration, renewable}' creds.json
```

The three lease fields are:

| Field | Meaning |
| --- | --- |
| `lease_id` | The identifier. It starts with the path that created the secret, `database/creds/inventory-readonly/`, followed by a random part. |
| `lease_duration` | How many seconds the lease lasts from now. Here 600, the role's `default_ttl`. |
| `renewable` | Whether the lease can be extended. Database credentials are renewable. |

The secret itself is in `data`, and a secret without a lease would have no `lease_id`. A KV version 2 read returns no lease, because OpenBao cannot end a stored secret.

## Look a lease up

`bao lease lookup` shows the state of one lease. It needs the lease ID, so keep it in a variable:

```sh
LEASE_ID=$(jq -r '.lease_id' creds.json)
bao lease lookup "$LEASE_ID"
```

The output has the `id`, the time the lease was issued (`issue_time`), when it expires (`expire_time`), when it was last renewed (`last_renewal`, empty if never), whether it is `renewable`, and the remaining `ttl`. The same information is available over the API:

```sh
bao write -format=json sys/leases/lookup lease_id="$LEASE_ID" | jq '.data | {issue_time, expire_time, ttl, renewable}'
```

The lookup works only while the lease exists. After the lease expires or is revoked, the lookup fails with an `invalid lease` error.

## What the lease controls

The lease ties three things together: the entry in OpenBao, the user in PostgreSQL, and the time the user is allowed to live. Check the user in the database while the lease is active:

```sh
kubectl -n data exec -i deploy/postgres -- env PGPASSWORD=postgres-admin-password \
    psql -h postgres.data -U postgres -d inventory -c '\du'
```

The generated user (a name that starts with `v-`) is in the list. When the lease ends, OpenBao runs the role's revocation statements, and the user disappears from the list.

```mermaid
sequenceDiagram
    participant A as application
    participant O as OpenBao
    participant P as PostgreSQL
    A->>O: read database/creds/inventory-readonly
    O->>P: CREATE ROLE
    O-->>A: username, password, lease_id, lease_duration
    Note over O: lease expires or is revoked
    O->>P: DROP ROLE
```

The diagram shows that the lease ID is the handle for ending the credential later, and that the database user exists only as long as the lease does.

You now know what a lease contains and how to read it. The next question is how long it can last, and the next part answers it.

## Common pitfalls

> [!WARNING]
> - **Losing the lease ID.** Without it you must search for the lease. Store it next to the credential.
> - **Treating `lease_duration` as a fixed time.** It is the time left when the response was made. Use `bao lease lookup` for the current value.
> - **Expecting a lease on every secret.** Static secrets such as KV have none.
