# Solution: Clean Up After A Database Credential Leak

Work the task yourself first. Running `astrona submit -c sections/section-030/capstone/labs/lab-01` after a step tells you which checks pass.

The grader checks four things: the lease times of the role, the four leaked leases and their users, the old connection password, and that OpenBao still creates working credentials.

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

## Step 2: Look at the damage

```sh
bao read database/roles/inventory-readonly
bao list sys/leases/lookup/database/creds/inventory-readonly/
```

The role shows `default_ttl` and `max_ttl` of 768 hours. The list shows the IDs of the four leaked leases.

## Step 3: Shorten the leases of the role

Write the role again with the same creation statements and new times. Save this as `inventory-readonly.sql`:

```sql
CREATE ROLE "{{name}}" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';
GRANT SELECT ON ALL TABLES IN SCHEMA public TO "{{name}}";
```

Then:

```sh
bao write database/roles/inventory-readonly \
    db_name=inventory-db \
    creation_statements=@inventory-readonly.sql \
    default_ttl=15m max_ttl=1h
```

Changing the role does not shorten leases that already exist: it applies to new credentials only. The leaked ones must be revoked.

## Step 4: Revoke every lease of the role at once

Every lease ID starts with the path it was read from, so one prefix covers them all. `-sync` waits until the revocations are done:

```sh
bao lease revoke -prefix -sync database/creds/inventory-readonly
bao list sys/leases/lookup/database/creds/inventory-readonly/
```

The list is now empty, which `bao` reports as no value found. OpenBao dropped the four database users while revoking.

## Step 5: Rotate the root credential

The leaked `openbao_admin` password must stop working. Rotating the root credential sets a new password that only OpenBao knows:

```sh
bao write -force database/rotate-root/inventory-db
```

## Step 6: Prove it

```sh
kubectl -n data exec -i deploy/postgres -- env PGPASSWORD=openbao-admin-password \
    psql -h 127.0.0.1 -U openbao_admin -d inventory -c 'SELECT 1'
bao read database/creds/inventory-readonly
```

The `psql` login fails with a password authentication error, and OpenBao still returns a new credential.

## Step 7: Submit

```sh
astrona submit -c sections/section-030/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Only change the role's TTLs | The four leaked credentials keep their month-long leases |
| Revoke the four leases one by one and forget one | One leaked user stays valid; the prefix catches every lease of the role |
| Reset `openbao_admin` with the superuser | The new password is known to a person again, and OpenBao can no longer connect |
| Delete the connection and create it again | Its leases stay orphaned, and the task forbids it |
