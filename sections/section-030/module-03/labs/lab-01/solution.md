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

## Step 2: Create the password policy

Save this as `inventory-password.hcl`:

```hcl
length = 24

rule "charset" {
  charset   = "abcdefghijklmnopqrstuvwxyz"
  min-chars = 1
}

rule "charset" {
  charset   = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
  min-chars = 1
}

rule "charset" {
  charset   = "0123456789"
  min-chars = 1
}
```

```sh
bao write sys/policies/password/inventory-password policy=@inventory-password.hcl
bao read -field=password sys/policies/password/inventory-password/generate
```

The generated password has 24 characters.

## Step 3: Change the connection

Send every field again, with the two new ones, so that no setting is lost:

```sh
bao write database/config/inventory-db \
    plugin_name=postgresql-database-plugin \
    allowed_roles=writer \
    connection_url='postgresql://{{username}}:{{password}}@postgres.data:5432/inventory?sslmode=disable' \
    username=openbao_admin \
    password=openbao-admin-password \
    password_authentication=scram-sha-256 \
    username_template='inv-{{.RoleName}}-{{random 8}}' \
    password_policy=inventory-password
```

## Step 4: Create the role

Save the creation statements as `writer-create.sql`:

```sql
CREATE ROLE "{{name}}" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO "{{name}}";
```

and the revocation statements as `writer-revoke.sql`:

```sql
REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM "{{name}}";
DROP ROLE IF EXISTS "{{name}}";
```

```sh
bao write database/roles/writer \
    db_name=inventory-db \
    creation_statements=@writer-create.sql \
    revocation_statements=@writer-revoke.sql \
    default_ttl=15m max_ttl=1h
```

## Step 5: Check

```sh
bao read -format=json database/creds/writer | jq -r '.data.username, .lease_id'
```

The user name starts with `inv-writer-`. Revoke the lease with `bao lease revoke <lease_id>` and check that the user is gone from `\du`.

## Step 6: Submit

Run `astrona submit` after each step to see which check passes.

## Why this works

The template and the policy are connection settings, so they apply to every credential of the role. The creation statements grant three rights and never `DELETE`. The revocation statements take the grants back first, so PostgreSQL allows the `DROP ROLE`.
