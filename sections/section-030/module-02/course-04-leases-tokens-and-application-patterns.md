# Leases, Tokens And Application Patterns

A lease is not independent of the token that requested it. When the token ends, its leases end with it. This part shows that link, and then describes the loop an application should run to use short-lived credentials without outages.

## Set up your terminal

The commands in this part need the database engine with the connection `inventory-db` and the role `inventory-readonly`, and a policy that lets a token read credentials.

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
printf 'path "database/creds/inventory-readonly" {\n  capabilities = ["read"]\n}\n' | bao policy write inventory-db-read -
```

If the engine, connection or role exist, ignore the errors.

## Leases belong to a token

Create a token with the policy, and read a credential with it. Use `BAO_TOKEN` only for that command:

```sh
APP_TOKEN=$(bao token create -policy=inventory-db-read -ttl=1h -field=token)
BAO_TOKEN="$APP_TOKEN" bao read -format=json database/creds/inventory-readonly | jq -r '.lease_id'
bao list sys/leases/lookup/database/creds/inventory-readonly
```

The lease is in the list. Revoke the token:

```sh
bao token revoke "$APP_TOKEN"
bao list sys/leases/lookup/database/creds/inventory-readonly
```

Revoking a token revokes the leases it created, so the list is empty after a moment and the user is dropped in PostgreSQL. The same happens when the token expires. This is why an application must renew its token as well as its credentials, and why a short token TTL ends credentials sooner than the lease times suggest.

## The application loop

An application that uses a database credential should follow these rules:

1. Read a credential at start-up and keep the `lease_id` and `lease_duration`.
2. Renew the lease when about half of the duration has passed. A renewal that fails once should be retried.
3. When the renewal fails or the lease reaches `max_ttl`, read a new credential, open new connections with it, and let the old connections finish.
4. On shutdown, revoke the lease with `bao lease revoke`, or let it expire, so no user is left behind.

The application needs a policy with `update` on `sys/leases/renew` and, for step 4, on `sys/leases/revoke`. Reading the credential needs only `read` on the creds path. An application must never receive `list` on `sys/leases/lookup/`, because the lease IDs of other applications are not its business.

## Cleaning up leftovers

If OpenBao records leases that point to nothing, for example after a restore, run the lease tidy operation:

```sh
bao write -f sys/leases/tidy
```

It removes stale lease entries. It is a background job and it does not touch live leases.

```mermaid
flowchart TB
    T["token (renewed by the app)"] -->|"creates"| L1["lease A"]
    T -->|"creates"| L2["lease B"]
    T -.->|"revoked or expired"| X["leases A and B revoked"]
```

The diagram shows that the token is the parent of its leases, and that ending the token ends them.

You now know how to read, renew, list and revoke leases, and why the token matters. This completes the lease lifecycle.

## Common pitfalls

> [!WARNING]
> - **Letting an application token expire.** All its credentials are revoked at once.
> - **Renewing at the last second.** One failed request then means an outage. Renew at about half of the duration.
> - **Giving the application `list` on `sys/leases/lookup/`.** It can then see the lease IDs of other applications.

## Your mission: Revoke And Renew Database Leases

You can now read a lease, renew it within its limits, list leases and revoke one or many. The graded lab gives you an engine with three old leases, and asks you to revoke them all, shorten the role's TTLs and keep one renewed credential for the application.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-114-playground-030-02
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS114.git -c sections/section-030/module-02/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-030/module-02/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-114-lab-030-02
astrona start ats-114-playground-030-02
```
