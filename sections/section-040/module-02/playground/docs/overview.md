# Overview: Signing, Verifying And Hashing With The Transit Engine (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs OpenBao and initializes and unseals it, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **OpenBao v2.7.1** in the namespace `openbao`, one pod `openbao-0`, initialized with one lab-only unseal key and already unsealed. The Transit engine is not enabled yet.
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

`b64` encodes text for Transit without line breaks. `sign_text` signs text with a key and `verify_text` checks a signature and prints `valid`.

```sh
b64() { printf '%s' "$1" | base64 | tr -d '\n'; }
sign_text() { bao write -field=signature transit/sign/"$1" input="$(b64 "$2")"; }
verify_text() { bao write -field=valid transit/verify/"$1" input="$(b64 "$2")" signature="$3"; }
```

Enable the engine first with `bao secrets enable transit`, and create keys with `bao write -f transit/keys/<name> type=ed25519`.

## Practice tasks

- Create an `ed25519` key, sign a text with `sign_text`, and verify it with `verify_text`. Change one character and verify again.
- Create an `rsa-2048` key and sign with `hash_algorithm=sha2-512`. Verify without that option and with it.
- Rotate a signing key, sign again, and verify both signatures. Compare the `vault:vN` prefix.
- Create a key with the default type and try to sign with it. Read the error.
- Compute an HMAC with `transit/hmac/<key>`, verify it with `hmac=`, and change the input.
- Write the signer and verifier policies from the module and test each with a token.
- Create an exportable throwaway key, export it, then back it up and restore it under a new name.
