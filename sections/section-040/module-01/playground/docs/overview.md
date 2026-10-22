# Overview: Encrypt Data With The Transit Engine (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs OpenBao and initializes and unseals it, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **OpenBao v2.7.1** in the namespace `openbao`, one pod `openbao-0`, initialized with one lab-only unseal key and already unsealed. There is no Transit mount yet.
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

`encrypt_text` encrypts a text with the key `inventory-records` and prints the ciphertext. `decrypt_text` decrypts a ciphertext and prints the text. `key_versions` prints the latest and the minimum decryption version of the key.

```sh
encrypt_text() {
  bao write -field=ciphertext transit/encrypt/inventory-records plaintext=$(printf '%s' "$1" | base64)
}
decrypt_text() {
  bao write -field=plaintext transit/decrypt/inventory-records ciphertext="$1" | base64 -d; echo
}
key_versions() {
  bao read -format=json transit/keys/inventory-records | jq '{latest: .data.latest_version, min_decryption: .data.min_decryption_version}'
}
```

Use them like this: `CT=$(encrypt_text 'hello')`, then `decrypt_text "$CT"` and `key_versions`.

## Practice tasks

- Encrypt the same text three times and compare the ciphertexts.
- Rotate the key twice, encrypt once after each rotation, and decrypt all three ciphertexts.
- Rewrap a `v1` ciphertext and check its new prefix.
- Raise `min_decryption_version` and try to decrypt an old ciphertext. Then lower it again and try once more.
- Create a second key with `type=ed25519` and compare what you can do with it (sign and verify, not encrypt).
- Ask for a data key with `transit/datakey/plaintext/inventory-records` and decrypt its `ciphertext` field.
