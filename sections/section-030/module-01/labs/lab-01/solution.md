# Solution: Give The Inventory App Expiring Database Credentials

Work the task yourself first. Running `astrona submit -c sections/section-030/module-01/labs/lab-01` after a step tells you which checks pass.

The grader checks three things: the connection, the lease times of the role, and a real credential that can read, cannot write and disappears when revoked.

## Step 1: Connect your terminal

Start the port-forward in a second terminal and leave it running:

```sh
kubectl -n openbao port-forward svc/openbao 8200:8200
```

Then:

```sh
export BAO_ADDR=http://openbao.localtest.me:8200
export BAO_TOKEN=$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)
```

## Step 2: Enable the engine and write the connection

The connection URL uses the Service name, because OpenBao runs in its own pod. Keep the placeholders; OpenBao fills them in with `username` and `password`.

```sh
bao secrets enable database
bao write database/config/inventory-db \
    plugin_name=postgresql-database-plugin \
    allowed_roles=inventory-readonly \
    connection_url='postgresql://{{username}}:{{password}}@postgres.data:5432/inventory?sslmode=disable' \
    username=openbao_admin \
    password=openbao-admin-password \
    password_authentication=scram-sha-256
```

## Step 3: Write the role

Save this as `inventory-readonly.sql`:

```sql
CREATE ROLE "{{name}}" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';
GRANT SELECT ON ALL TABLES IN SCHEMA public TO "{{name}}";
```

Write the role:

```sh
bao write database/roles/inventory-readonly \
    db_name=inventory-db \
    creation_statements=@inventory-readonly.sql \
    default_ttl=10m max_ttl=1h
```

## Step 4: Prove it

Read a credential, use it, and revoke it:

```sh
bao read -format=json database/creds/inventory-readonly > creds.json
DB_USER=$(jq -r '.data.username' creds.json)
DB_PASSWORD=$(jq -r '.data.password' creds.json)
kubectl -n data exec -i deploy/postgres -- env PGPASSWORD="$DB_PASSWORD" \
    psql -h postgres.data -U "$DB_USER" -d inventory -c 'SELECT count(*) FROM items'
bao lease revoke "$(jq -r '.lease_id' creds.json)"
```

The count is `3`. After the revocation, `\du` as the superuser no longer lists the user.

## Step 5: Submit

```sh
astrona submit -c sections/section-030/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Connect as `postgres` | Works, but OpenBao then holds the keys to the whole database; the grader checks the connection user |
| `GRANT ALL` in the creation statements | The users can change data; the grader tries an `INSERT` |
| `default_ttl=10m` without `max_ttl` | Renewals can keep a credential alive up to the mount maximum; the grader checks for 1 hour |
| Writing the real password into `connection_url` | The root credential can no longer be rotated cleanly |
