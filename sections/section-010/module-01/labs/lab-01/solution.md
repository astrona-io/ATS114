# Solution: Recover A Secret After A Bad Write

Work the task yourself first. Running `astrona submit -c sections/section-010/module-01/labs/lab-01` after a step tells you which checks pass.

The grader checks four things: the current data of `inventory/db`, that `inventory/api` is back at version 1, that both secrets keep their original version 1, and the version limit.

## Step 1: Connect your terminal

Start the port-forward in a second terminal and leave it running:

```sh
kubectl -n openbao port-forward svc/openbao 8200:8200
```

Then point `bao` at the server with the lab-only root token:

```sh
export BAO_ADDR=http://openbao.localtest.me:8200
export BAO_TOKEN=$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)
```

## Step 2: Read the history of inventory/db

```sh
bao kv metadata get -mount=secret inventory/db
bao kv get -mount=secret -version=2 inventory/db
bao kv get -mount=secret -version=3 inventory/db
```

The metadata shows three versions. Version 3, the current one, holds the placeholder `CHANGEME`. Version 2 holds the password `Inv-2026-b`, the last good value.

## Step 3: Roll back inventory/db

`bao kv rollback` copies the data of version 2 into a new version, so you never type the password:

```sh
bao kv rollback -mount=secret -version=2 inventory/db
bao kv get -mount=secret inventory/db
```

The current version is now 4, with the data of version 2. Version 3 stays in the history.

## Step 4: Undelete inventory/api

Read the history first: the only version, 1, has a `deletion_time`. That is a soft delete, so the data is still in storage.

```sh
bao kv metadata get -mount=secret inventory/api
bao kv undelete -mount=secret -versions=1 inventory/api
bao kv get -mount=secret inventory/api
```

The secret is readable again at version 1, with the token `api-token-7731`. A `bao kv put` would have created version 2 instead, and the grader rejects that.

## Step 5: Limit the history of inventory/db

```sh
bao kv metadata put -mount=secret -max-versions=5 inventory/db
bao kv metadata get -mount=secret inventory/db
```

The metadata shows `max_versions` as `5`.

## Step 6: Submit

```sh
astrona submit -c sections/section-010/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| `bao kv put` with the old password | Works only if you know the value; the grader cannot tell it from a guess and the task forbids it |
| `bao kv put` for `inventory/api` | Creates version 2; the deleted version 1 stays deleted, and the grader expects version 1 back |
| `bao kv metadata delete` and write again | Removes the whole history, which the grader checks |
| `bao kv destroy -versions=3` only | Removes the bad data, but there is no current version left to read |
