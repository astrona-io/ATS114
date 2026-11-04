# Renewing And The TTL Limits

A lease starts with the role's `default_ttl`. If the application still needs the credential, it renews the lease. Renewal is not unlimited: more than one limit can stop it, and the shortest one wins. This part renews a lease, reaches the limit on purpose, and then looks at the limits that the mount sets for all roles.

## Set up your terminal

The commands in this part need the database engine with the connection `inventory-db` and the role `inventory-readonly` (`default_ttl=10m`, `max_ttl=1h`).

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

## Renew a lease

Read a credential and renew its lease with an increment. The increment is the lease time you ask for, counted from now, not an amount added to the old time:

```sh
LEASE_ID=$(bao read -format=json database/creds/inventory-readonly | jq -r '.lease_id')
bao lease renew -increment=30m "$LEASE_ID"
bao lease lookup "$LEASE_ID"
```

The renewal answer shows `lease_duration` of `1800`, and the lookup shows a `last_renewal` time and a `ttl` close to 30 minutes. The lease in OpenBao is extended. The user in PostgreSQL keeps the `VALID UNTIL` time it was created with, unless the role has `renew_statements` that change it. If the database must follow the lease, add `renew_statements` to the role; otherwise the database refuses the password at the original time even though the lease is still active.

## The limits

Three values decide how long a lease can live:

| Limit | Set on | Meaning |
| --- | --- | --- |
| `default_ttl` | the role | The lease at creation and the default increment. |
| `max_ttl` | the role | The longest the lease may live in total, counted from creation, including all renewals. |
| `max-lease-ttl` | the mount | A hard upper limit for every lease below this mount. A role's `max_ttl` above it is cut to it. |

Ask for more than the limit allows and OpenBao grants the limit instead of failing:

```sh
bao lease renew -increment=5h "$LEASE_ID"
```

The answer shows a `lease_duration` no larger than the time left until `max_ttl`, which is one hour after creation. Run the renew again after the maximum is reached and the lease still ends at the same moment; renewing does not move `max_ttl`.

Read the mount limits:

```sh
bao read sys/mounts/database/tune
```

The `default_lease_ttl` and `max_lease_ttl` fields show `0` when the mount uses the system values, which are 32 days for both by default. To lower the ceiling for the whole engine:

```sh
bao secrets tune -max-lease-ttl=2h database
```

Roles with a higher `max_ttl` are now cut to two hours. The mount limit does not change leases that exist.

```mermaid
flowchart TB
    R["role default_ttl 10m"] -->|"renew increment"| L["lease"]
    L --> X{"within limits?"}
    X -->|"role max_ttl 1h"| G["granted up to the limit"]
    X -->|"mount max-lease-ttl"| G
```

The diagram shows that a renewal is granted up to the nearest limit, never beyond it.

You can now renew leases and predict how far a renewal goes. Renewal keeps a lease alive; the next part ends leases.

## Common pitfalls

> [!WARNING]
> - **Expecting renewals to extend `max_ttl`.** The maximum is measured from creation. When it is reached, read a new credential.
> - **Reading `-increment` as an addition.** It is the new time from now.
> - **Lowering the mount limit and expecting old leases to shrink.** Only new leases and renewals follow the new limit.
