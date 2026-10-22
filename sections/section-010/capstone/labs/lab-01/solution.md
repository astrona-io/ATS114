# Solution: Clean Up A KV Mount Before An Audit

Work the task yourself first. Running `astrona submit -c sections/section-010/capstone/labs/lab-01` after a step tells you which checks pass.

The grader checks five things: the leaked version is destroyed, the current data of `inventory/db` is clean, `inventory/payments` requires check-and-set, the mount default, and that both secrets keep their original version 1.

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

## Step 2: Find the leaked version

```sh
bao kv metadata get -mount=secret inventory/db
bao kv get -mount=secret -version=3 inventory/db
bao kv get -mount=secret -version=2 inventory/db
```

Version 3, the current one, has the extra field `debug_dump`. Version 2 has the same password without it, so version 2 is the clean data.

## Step 3: Destroy the leaked version and roll back

A soft delete would keep the leaked data in storage, so destroy it. Then copy version 2 into a new current version:

```sh
bao kv destroy -mount=secret -versions=3 inventory/db
bao kv rollback -mount=secret -version=2 inventory/db
bao kv get -mount=secret inventory/db
bao kv metadata get -mount=secret inventory/db
```

The current version is 4, without `debug_dump`, and version 3 shows `destroyed` as `true`. The order does not matter: rolling back first and destroying afterwards gives the same result.

## Step 4: Require check-and-set on inventory/payments

```sh
bao kv metadata put -mount=secret -cas-required=true inventory/payments
bao kv metadata get -mount=secret inventory/payments
```

The metadata shows `cas_required` as `true`. From now on a write without `-cas` fails.

## Step 5: Set the mount default

The default for every secret lives in the configuration of the mount, at `secret/config`:

```sh
bao write secret/config max_versions=10
bao read secret/config
```

## Step 6: Submit

```sh
astrona submit -c sections/section-010/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| `bao kv delete` on version 3 | The leaked data stays in storage and can be undeleted |
| `bao kv patch` to remove `debug_dump` | The leaked value stays readable in version 3 |
| `bao kv metadata put -max-versions=10` on each secret | Sets the limit on those secrets only, not on the mount; the grader reads `secret/config` |
| Delete the metadata and write the secret again | The whole history is gone, which the grader checks |
