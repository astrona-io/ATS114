# Rotating The Root Credential And Static Roles

Every dynamic user OpenBao creates is short-lived, but the user OpenBao connects as is not. Its password was typed into the connection by a person, it may sit in a shell history or a ticket, and it can create users in the database. This part takes that password away from people: OpenBao rotates it to a value only OpenBao knows. It then looks at the other side of the same idea, a static role, for users that must keep their name.

## Set up your terminal

The commands in this part need the connection `inventory-db` at `database/`, which allows the roles `inventory-readonly` and `inventory-report`.

<!-- astrona:playground:renew -->

Start the port-forward in a second terminal and leave it running:

```sh
kubectl -n openbao port-forward svc/openbao 8200:8200
```

Then point `bao` at the server with the lab-only root token:

```sh
export BAO_ADDR=http://openbao.localtest.me:8200
export BAO_TOKEN=$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)
```

## Rotate the root credential

The root credential of a connection is the `username` and `password` you wrote into it. The endpoint `database/rotate-root/<connection>` makes OpenBao set a new random password for that user in the database and store it, without returning it to anyone.

Before you rotate, prove the old password works, so you can see the difference afterwards:

```sh
kubectl -n data exec -i deploy/postgres -- env PGPASSWORD=openbao-admin-password \
    psql -h 127.0.0.1 -U openbao_admin -d inventory -c 'SELECT 1'
```

The query returns `1`. Now rotate, and try the old password again:

```sh
bao write -force database/rotate-root/inventory-db
kubectl -n data exec -i deploy/postgres -- env PGPASSWORD=openbao-admin-password \
    psql -h 127.0.0.1 -U openbao_admin -d inventory -c 'SELECT 1'
```

`-force` sends the write without data, because this endpoint needs none. After the rotation, the same `psql` command fails with a password authentication error: the password you know is no longer valid. OpenBao still works, because it uses the new password it stored. Read a credential from `database/creds/inventory-readonly` to see that for yourself.

The consequence is deliberate: after a rotation, nobody but OpenBao can log in as `openbao_admin`. If a person must ever get that access again, a database administrator resets the password with the superuser. That is why the OpenBao documentation warns against using a static role or rotation on credentials people still need.

## Static roles

Some users cannot get a new name on every request: a reporting tool may be configured with one user name in its own settings, or a database grant may name a specific user. A static role maps an OpenBao role to one existing database user and only rotates that user's password, on a schedule.

First create the user as the database administrator. `GRANT inventory_report TO openbao_admin WITH ADMIN OPTION` lets `openbao_admin` change this user's password, which PostgreSQL 16 and later require for a user it did not create:

```sh
kubectl -n data exec -i deploy/postgres -- env PGPASSWORD=postgres-admin-password \
    psql -h 127.0.0.1 -U postgres -d inventory \
    -c 'CREATE ROLE inventory_report LOGIN' \
    -c 'GRANT SELECT ON items TO inventory_report' \
    -c 'GRANT inventory_report TO openbao_admin WITH ADMIN OPTION'
```

Then write the static role and read its credentials:

```sh
bao write database/static-roles/inventory-report \
    db_name=inventory-db username=inventory_report rotation_period=24h
bao read database/static-creds/inventory-report
```

The response holds the user name `inventory_report`, its current password, the time of the last rotation and the seconds until the next one. There is no lease: the user is not dropped, only its password changes every 24 hours. Force a rotation now and read again:

```sh
bao write -force database/rotate-role/inventory-report
bao read database/static-creds/inventory-report
```

The password is different, and the time of the last rotation is new. A tool that reads the password from OpenBao before each connection keeps working; a tool with the old password in a file stops.

| | Dynamic role | Static role |
| --- | --- | --- |
| User | A new one per request | One existing user |
| Endpoint | `database/creds/<role>` | `database/static-creds/<role>` |
| Lease | Yes; the user is dropped at the end | No; only the password rotates |
| Use it when | The application can use any user name | The user name must stay the same |

You now know how to take the connection password away from people, and how to manage a user whose name must not change. With roles, leases and these two forms of rotation, the database secrets engine controls every credential the application side ever sees.

## Common pitfalls

> [!WARNING]
> - **Rotating the root credential of a user people still log in with.** After the rotation only OpenBao knows the password. Give OpenBao its own user.
> - **Using a static role for the connection user.** The OpenBao documentation warns against it: rotating it through a static role can break every user the connection manages. Use `rotate-root`.
> - **Expecting a lease on static credentials.** There is none to renew or revoke; the password simply rotates on its schedule.
> - **Missing the admin grant on PostgreSQL 16 and later.** Without `WITH ADMIN OPTION`, `openbao_admin` cannot change the password of a user it did not create, and the rotation fails.
