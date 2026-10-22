# Overview: Store And Version Secrets With KV Version 2 (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs OpenBao and initializes and unseals it, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **OpenBao v2.7.1** in the namespace `openbao`, one pod `openbao-0`, initialized with one lab-only unseal key and already unsealed. Nothing is enabled yet: there is no KV mount until you create one.
- The lab-only root token and unseal key in the Kubernetes Secret `openbao-init`. A real installation never keeps them there.
- The **`bao`** command-line tool v2.7.1 on your PATH.
- A `tester` pod in the namespace `clients` with `curl`, `jq` and `openssl`.

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

`show_history` prints the version history of one secret in the mount `secret/`, as compact JSON with one line per version.

```sh
show_history() {
  bao kv metadata get -format=json -mount=secret "$1" \
    | jq -c '.data.versions | to_entries[] | {version: .key, created: .value.created_time, deleted: .value.deletion_time, destroyed: .value.destroyed}'
}
```

Use it like this: `show_history inventory/db`.

## Practice tasks

- Enable KV version 2 at `secret/` and a second time at `team-a/`. Write the same path in both mounts and read them separately.
- Write five versions of a secret with `put`, then patch one field. Compare the data of the last two versions.
- Soft-delete version 2, read it, and undelete it. Then destroy it and try to undelete it again.
- Roll back to version 1 and check which version number the rollback creates.
- Set `max_versions` to 2 on a secret with five versions, read the history, write once more and read it again.
- Turn on `cas_required` and try three writes: without `-cas`, with the right version, and with an old version.
