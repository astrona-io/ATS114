# Overview: Configuring The Database Engine: Templates, Policies And Statements (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs OpenBao and initializes and unseals it, starts PostgreSQL, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **OpenBao v2.7.1** in the namespace `openbao`, one pod `openbao-0`, initialized with one lab-only unseal key and already unsealed. There is no database engine yet.
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

`rights USER` prints whether a generated user may select, insert, update and delete rows of `items`. `pg_users` lists the generated users.

```sh
rights() {
  kubectl -n data exec -i deploy/postgres -- env PGPASSWORD=postgres-admin-password \
    psql -h postgres.data -U postgres -d inventory -tA \
    -c "SELECT has_table_privilege('$1','items','SELECT'), has_table_privilege('$1','items','INSERT'), has_table_privilege('$1','items','UPDATE'), has_table_privilege('$1','items','DELETE')"
}
pg_users() {
  kubectl -n data exec -i deploy/postgres -- env PGPASSWORD=postgres-admin-password \
    psql -h postgres.data -U postgres -d inventory -tA -c "SELECT rolname FROM pg_roles WHERE rolname LIKE 'v-%' OR rolname LIKE 'inv-%'"
}
```

Enable the engine first with `bao secrets enable database` and write the connection `inventory-db` as in the first part.

## Practice tasks

- Set a `username_template`, read three credentials from one role, and compare the names.
- Write a template without `random`, read two credentials from the same role, and read the error.
- Write a password policy with a length of 10 and three rules that each need 5 characters, then generate a password from it.
- Write a role whose revocation statements only drop the role, read a credential, revoke it, and look at `pg_users`.
- Add a second connection with `allowed_roles` set to one role name, and read a credential from a role it does not allow.
- Set `max_open_connections=1` and read several credentials in a row.
