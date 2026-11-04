# Overview: Issuers And Root Rotation In The PKI Engine (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs OpenBao and initializes and unseals it, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **OpenBao v2.7.1** in the namespace `openbao`, one pod `openbao-0`, initialized with one lab-only unseal key and already unsealed. There is no PKI mount yet.
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

`issuer_table` prints the name, ID and usage of every issuer. `issuing_subject` issues a certificate from a role and prints the subject of its issuing CA.

```sh
issuer_table() {
  for id in $(bao list -format=json pki/issuers | jq -r '.[]'); do
    bao read -format=json pki/issuer/$id | jq -r '.data | [.issuer_name, .issuer_id, .usage] | @tsv'
  done
}
issuing_subject() {
  bao write -format=json pki/issue/"$1" common_name=api.inventory.svc | jq -r '.data.issuing_ca' | openssl x509 -noout -subject
}
```

Use them like this: `issuer_table`, `issuing_subject inventory-svc`.

## Practice tasks

- Generate two roots with different names and compare `bao list pki/issuers` and `bao list pki/keys`.
- Change the default issuer and issue a certificate with `issuing_subject`.
- Pin a role with `issuer_ref` and change the default again. Which issuer signs?
- Set `usage=crl-signing` on an issuer and try to issue from a role pinned to it.
- Read the certificate of each issuer with `bao read -field=certificate pki/issuer/<name>` and check its dates with `openssl x509 -noout -dates`.
- Delete an issuer, then its key, and read `pki/config/issuers`.
