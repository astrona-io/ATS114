# Solution

## Step 1: Connect

Start the port-forward in a second terminal and leave it running:

```sh
kubectl -n openbao port-forward svc/openbao 8200:8200
```

In the first terminal:

```sh
export BAO_ADDR=http://openbao.localtest.me:8200
export BAO_TOKEN=$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)
```

## Step 2: Revoke the old leases

List the leases, and then revoke everything under the role:

```sh
bao list sys/leases/lookup/database/creds/inventory-readonly
bao lease revoke -prefix database/creds/inventory-readonly
```

Wait a few seconds and list again. The list is empty (`No value found`). Check that the users are gone:

```sh
kubectl -n data exec -i deploy/postgres -- env PGPASSWORD=postgres-admin-password \
    psql -h postgres.data -U postgres -d inventory -c '\du'
```

## Step 3: Change the role

A write to a role replaces its fields, so send the connection name and the creation statements again together with the new TTLs. Save the SQL in `inventory-readonly.sql`:

```sql
CREATE ROLE "{{name}}" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';
GRANT SELECT ON ALL TABLES IN SCHEMA public TO "{{name}}";
```

```sh
bao write database/roles/inventory-readonly \
    db_name=inventory-db \
    creation_statements=@inventory-readonly.sql \
    default_ttl=5m max_ttl=30m
```

## Step 4: Read and renew one credential

Do this after step 2, so the new lease is not revoked:

```sh
LEASE_ID=$(bao read -format=json database/creds/inventory-readonly | jq -r '.lease_id')
bao lease renew -increment=20m "$LEASE_ID"
bao lease lookup "$LEASE_ID"
```

## Step 5: Submit

Run `astrona submit` after each step to see which check passes.

## Why this works

The prefix revoke ends all leases of the role at once and runs the revocation statements for every user. The role write changes the limits for new leases. The renewal is granted up to the new `max_ttl` of 30 minutes, so 20 minutes is allowed.
