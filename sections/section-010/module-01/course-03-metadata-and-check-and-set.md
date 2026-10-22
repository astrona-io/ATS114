# Metadata, Version Limits And Check-And-Set

Two problems come with a version history. The first is size: a secret that changes every hour builds up thousands of versions, and old passwords stay readable long after they stopped mattering. The second is concurrency: two scripts read the same secret, each changes one thing, and the second write silently undoes the first. KV version 2 solves both with settings in the metadata of a secret or of the whole mount.

## Set up the example secrets

The commands in this part need the port-forward (`kubectl -n openbao port-forward svc/openbao 8200:8200`) running in a second terminal, and the KV version 2 mount `secret/`.

<!-- astrona:playground:renew -->

Point `bao` at the server with the lab-only root token. If the mount already exists, ignore the error from `enable`:

```sh
export BAO_ADDR=http://openbao.localtest.me:8200
export BAO_TOKEN=$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)
bao secrets enable -path=secret kv-v2
bao kv put -mount=secret inventory/payments api_key=pay-live-1234
```

## Limiting the history

The setting `max_versions` says how many versions a secret keeps. When a write takes the count above the limit, the KV engine removes the oldest versions, data and metadata, for good. A related setting, `delete_version_after`, soft-deletes each new version after a set time.

Set both on one secret, then write to it and read the history:

```sh
bao kv metadata put -mount=secret -max-versions=3 -delete-version-after=720h inventory/payments
bao kv put -mount=secret inventory/payments api_key=pay-live-5678
bao kv metadata get -mount=secret inventory/payments
```

The metadata now shows `max_versions` as `3` and `delete_version_after` as `720h0m0s`. Two facts from the OpenBao documentation matter here: the new `max_versions` is applied on the next write, and `delete_version_after` applies only to versions written after you set it.

A setting on one secret is easy to forget for the next one. The mount has its own configuration at the path `secret/config`, which every secret uses unless it sets its own value:

```sh
bao write secret/config max_versions=10
bao read secret/config
```

`bao read secret/config` shows `max_versions` as `10` for the whole mount. A secret with its own `max_versions` keeps its own limit; a secret without one keeps at most 10 versions.

## Check-and-set

Check-and-set (CAS) is a rule for writes: the writer names the version it expects to replace, and the KV engine accepts the write only if that version is still the current one. If someone else wrote in between, the write fails instead of silently undoing their change.

Turn the rule on for `inventory/payments`, then try a write without it:

```sh
bao kv metadata put -mount=secret -cas-required=true inventory/payments
bao kv put -mount=secret inventory/payments api_key=pay-live-9999
```

The write fails: the KV engine answers that the check-and-set parameter is required for this secret. Read the current version number from `bao kv metadata get` (it is `2` if you followed this part), and write again with `-cas`:

```sh
bao kv put -mount=secret -cas=2 inventory/payments api_key=pay-live-9999
bao kv put -mount=secret -cas=2 inventory/payments api_key=pay-live-0000
```

The first write succeeds and creates version 3. The second write fails, because version 2 is no longer the current one: this is exactly the lost update that check-and-set prevents. The special value `-cas=0` means "write only if the secret does not exist yet", which a script can use to create a secret without overwriting one.

You now know how to keep the history of a secret small, set a default for a whole mount, and make writes safe when several writers share a secret. Together with versions, deletes and rollback, that is everything the KV version 2 engine offers for keeping static secrets correct.

## Common pitfalls

> [!WARNING]
> - **Expecting `max_versions` to clean up at once.** The limit is applied on the next write to the secret, not when you set it.
> - **Expecting `delete_version_after` to touch old versions.** It applies only to versions written after the setting.
> - **Turning on `cas_required` without telling the writers.** Every script that writes the secret without `-cas` starts to fail. Update the scripts first.
> - **Setting the mount default at `secret/metadata/config`.** The mount configuration lives at `secret/config`.

## Your mission: Recover A Secret After A Bad Write

You can now find the last good version of a secret, restore it, undo a deletion and limit the history. The graded lab gives you two damaged secrets in the mount `secret/`: one with a bad current version and one deleted by mistake. It asks you to recover both without writing their values again by hand, and to limit one of them to five versions.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-114-playground-010-01
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS114.git -c sections/section-010/module-01/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-010/module-01/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-114-lab-010-01
astrona start ats-114-playground-010-01
```
