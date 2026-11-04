# Overview: Cubbyhole And Response Wrapping (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs OpenBao and initializes and unseals it, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **OpenBao v2.7.1** in the namespace `openbao`, one pod `openbao-0`, initialized with one lab-only unseal key and already unsealed. The KV mount `secret/` does not exist yet.
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

`wrap_info` prints the creation path and the TTL of a wrapping token without using it.

```sh
wrap_info() {
  bao write -format=json sys/wrapping/lookup token="$1" | jq '.data | {creation_path, creation_ttl}'
}
```

Use it like this: `WRAP=$(bao read -wrap-ttl=5m -field=wrapping_token secret/data/inventory/api)`, then `wrap_info "$WRAP"`.

## Practice tasks

- Write to `cubbyhole/notes` with two different tokens and read it with each.
- Wrap a secret, unwrap it, and try to unwrap it again.
- Wrap a secret with `-wrap-ttl=10s`, wait, and try to unwrap it.
- Create a token with `bao token create -wrap-ttl=2m` and unwrap it into `.auth.client_token`.
- Write the policy from the reading, create a token for it and try a read with no wrap TTL, a long one and a short one.
- Rewrap a token with `sys/wrapping/rewrap` and check that the old token no longer works.
