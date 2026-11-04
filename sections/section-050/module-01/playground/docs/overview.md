# Overview: Time-Based One-Time Passwords With The TOTP Engine (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs OpenBao and initializes and unseals it, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **OpenBao v2.7.1** in the namespace `openbao`, one pod `openbao-0`, initialized with one lab-only unseal key and already unsealed. The TOTP engine is not enabled yet.
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

`totp_check KEY` generates a code for a key and validates it, so you can see the `valid` answer. `totp_show URL` prints the parts of an `otpauth://` URL on separate lines.

```sh
totp_check() {
  CODE=$(bao read -field=code totp/code/"$1")
  echo "code: $CODE"
  bao write -field=valid totp/code/"$1" code="$CODE"
}
totp_show() { printf '%s\n' "$1" | tr '?&' '\n\n'; }
```

Enable the engine first with `bao secrets enable totp`.

## Practice tasks

- Create a generated key, print its URL with `totp_show`, and read the key back. Which values does the read leave out?
- Run `totp_check` twice within one period. What changes in the answer?
- Import `otpauth://totp/Partner:ops@partner.example?secret=JBSWY3DPEHPK3PXP&issuer=Partner` as a key, and read its settings.
- Create the same secret as two keys, one with the URL and one with `key=`, and compare the codes.
- Create a key with `period=15` and `digits=8`, and watch the code change.
- Write a policy with only `update` on one code path, and test it with a token for validate and generate.
- Mount a second engine at `totp-prod` and create a key there.
