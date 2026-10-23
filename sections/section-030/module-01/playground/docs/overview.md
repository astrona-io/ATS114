# Overview: Generate Short-Lived Database Credentials (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs OpenBao and initializes and unseals it, starts PostgreSQL, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **OpenBao v2.7.1** in the namespace `openbao`, one pod `openbao-0`, initialized with one lab-only unseal key and already unsealed. The database engine is not enabled yet.
- The lab-only root token and unseal key in the Kubernetes Secret `openbao-init`. A real installation never keeps them there.
- **PostgreSQL 17** in the namespace `data`, Deployment and Service `postgres`, database `inventory` with the table `items` (three rows). Lab-only users: `postgres` / `postgres-admin-password` (superuser) and `openbao_admin` / `openbao-admin-password` (may create roles and grant table access).
- The **`bao`** command-line tool v2.7.1 on your PATH, and a `tester` pod in the namespace `clients`.

## Connect your terminal

Start the port-forward in a second terminal and leave it running:

```sh
kubectl -n openbao port-forward svc/openbao 8200:8200
```

Then, in each terminal where you run `bao`:

```sh
export BAO_ADDR=http://openbao.localtest.me:8200
export BAO_TOKEN=$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)
```

## Helpers

`psql_as` runs `psql` in the PostgreSQL pod as the user and password you give it. `list_db_users` lists the roles in PostgreSQL as the superuser, so you can watch OpenBao create and drop users.

```sh
psql_as() {
  local db_user="$1" db_password="$2"; shift 2
  kubectl -n data exec -i deploy/postgres -- env PGPASSWORD="$db_password" \
    psql -h postgres.data -U "$db_user" -d inventory "$@"
}
list_db_users() {
  psql_as postgres postgres-admin-password -c '\du'
}
```

Use them like this: `list_db_users`, or `psql_as "$DB_USER" "$DB_PASSWORD" -c 'SELECT * FROM items'`.

## Practice tasks

- Write a role with `default_ttl=1m`, read a credential, and watch the user disappear from `list_db_users` about a minute later.
- Renew a lease with `-increment=2h` on a role with `max_ttl=1h` and read the duration OpenBao granted.
- Read five credentials and revoke them all at once with `bao lease revoke -prefix database/creds/inventory-readonly`.
- Remove `inventory-readonly` from the connection's `allowed_roles` and read a credential. Read the error.
- Rotate the root credential and try the old `openbao_admin` password with `psql_as`.
- Create a static role, rotate it twice with `database/rotate-role/`, and compare the passwords.
