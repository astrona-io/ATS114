# Password Policies

The password of a generated user is random, but the rules it follows are a setting. The default is 20 characters of letters and digits. A company may need a longer password, or a password that must contain a digit, an upper-case and a lower-case letter. OpenBao keeps these rules as password policies. This part writes one, tests it, and attaches it to the connection.

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

## Write a policy

A password policy is a small document in the same language as access policies. It sets a length and one or more character rules. Save this as `inventory-password.hcl`:

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

The policy needs a length of 24 characters and at least one lower-case letter, one upper-case letter and one digit. Characters outside the listed sets are not used. Write it under a name:

```sh
bao write sys/policies/password/inventory-password policy=@inventory-password.hcl
```

## Test the policy

Generating a password from the policy does not touch the database. Use it to check the rules:

```sh
bao read -field=password sys/policies/password/inventory-password/generate
```

The result is a 24-character string that contains the required kinds of characters. Run it several times to see that it differs each time.

## Attach it to the connection

Set `password_policy` on the connection, again with every field, so that no setting is lost:

```sh
bao write database/config/inventory-db \
    plugin_name=postgresql-database-plugin \
    allowed_roles="*" \
    connection_url='postgresql://{{username}}:{{password}}@postgres.data:5432/inventory?sslmode=disable' \
    username=openbao_admin \
    password=openbao-admin-password \
    password_authentication=scram-sha-256 \
    password_policy=inventory-password
bao read -field=password database/creds/inventory-readonly | awk '{ print length($0) }'
```

The last command prints `24`. Every role that uses this connection now gets passwords from the policy, including the passwords OpenBao sets when it rotates the root credential.

## Choose the rules with care

A policy that is too strict can be impossible to satisfy. A length of 10 with six rules that each need two characters cannot be met, and OpenBao refuses to generate. Keep the minimums well below the length. A password policy also does not change the password of users that already exist.

```mermaid
flowchart LR
    P["password policy"] -->|"generate"| W["24 characters"]
    C["connection: password_policy"] --> P
    W -->|"{{password}}"| S["creation statements"]
```

The diagram shows that the connection points at a policy, the policy produces the password, and the creation statements receive it as `{{password}}`.

You can now control name and password. What the user may do in the database is decided by the SQL in the role, and the next part covers it.

## Common pitfalls

> [!WARNING]
> - **Naming a password policy that does not exist.** The connection write fails or later reads fail. Write and test the policy first.
> - **Setting rules that cannot all be met.** The sum of the minimums must fit in the length.
> - **Using characters PostgreSQL or your SQL treat specially.** A single quote in the charset would break the creation statement; keep to letters and digits.
