# Overview: Lease Management For Database Credentials (Playground)

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

`pg_users` lists the generated database users. `lease_ids` prints the full lease ID of every active lease under the role `inventory-readonly`.

```sh
pg_users() {
  kubectl -n data exec -i deploy/postgres -- env PGPASSWORD=postgres-admin-password \
    psql -h postgres.data -U postgres -d inventory -tA -c "SELECT rolname FROM pg_roles WHERE rolname LIKE 'v-%'"
}
lease_ids() {
  bao list -format=json sys/leases/lookup/database/creds/inventory-readonly | jq -r '.[] | "database/creds/inventory-readonly/" + .'
}
```

Enable the engine first: `bao secrets enable database`, then write the connection `inventory-db` and the role `inventory-readonly` as in the first part.

## Practice tasks

- Read three credentials, run `lease_ids` and `pg_users`, then revoke one lease and compare both lists.
- Renew a lease with `-increment=5h` and compare the new TTL with the role's `max_ttl`.
- Tune the mount with `bao secrets tune -max-lease-ttl=2m database`, read a credential, and read its `lease_duration`.
- Create a token with a policy that can read credentials, read one credential with it, and revoke the token.
- Stop PostgreSQL with `kubectl -n data scale deploy/postgres --replicas=0`, revoke a lease, and read the lease and the user. Scale PostgreSQL back up and check again.
- Run `bao lease revoke -force` for a lease while PostgreSQL is stopped, and check the user afterwards.
