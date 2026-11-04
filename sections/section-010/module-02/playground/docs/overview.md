# Overview: Manage Secrets Engine Mounts (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs OpenBao and initializes and unseals it, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **OpenBao v2.7.1** in the namespace `openbao`, one pod `openbao-0`, initialized with one lab-only unseal key and already unsealed. There are only the built-in mounts.
- The lab-only root token and unseal key in the Kubernetes Secret `openbao-init`. A real installation never keeps them there.
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

`mount_table` prints the path, type and description of every mount as a table.

```sh
mount_table() {
  bao read -format=json sys/mounts | jq -r '.data | to_entries[] | [.key, .value.type, .value.description] | @tsv'
}
```

Use it like this: `mount_table`.

## Practice tasks

- Enable two KV version 2 mounts at different paths and write the same secret name in each.
- Tune a mount with a default TTL longer than its maximum and read the error or the result.
- Move a mount, then try to read from the old path and read the error.
- Create a version 1 mount, write a secret, upgrade it with `bao kv enable-versioning` and read the metadata.
- Compare `bao secrets list -detailed` before and after each change.
