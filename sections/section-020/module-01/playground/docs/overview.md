# Overview: Run An Internal Certificate Authority With The PKI Engine (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs OpenBao and initializes and unseals it, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **OpenBao v2.7.1** in the namespace `openbao`, one pod `openbao-0`, initialized with one lab-only unseal key and already unsealed. There are no PKI mounts yet.
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

`issue_cert` issues a certificate from the role `inventory-svc` on `pki_int/` for the name you give it, and saves the certificate as `<name>.pem`. `check_chain` verifies a saved certificate against the root and intermediate CA certificates, which it downloads first.

```sh
issue_cert() {
  bao write -field=certificate pki_int/issue/inventory-svc common_name="$1" ttl=1h > "$1.pem"
}
check_chain() {
  curl -s $BAO_ADDR/v1/pki/ca/pem > root-ca.pem
  curl -s $BAO_ADDR/v1/pki_int/ca/pem > intermediate-ca.pem
  openssl verify -CAfile root-ca.pem -untrusted intermediate-ca.pem "$1"
}
```

Use them like this: `issue_cert api.inventory.svc`, then `check_chain api.inventory.svc.pem`.

## Practice tasks

- Generate the root CA with a short `ttl` and no `tune` first, and read its dates with `openssl`. Then try again after tuning the mount.
- Build the intermediate, and try to issue a certificate before `set-signed`. Read the error.
- Write a second role `inventory-short` with `max_ttl=1h` and ask it for a certificate with `ttl=24h`. Compare the dates you get.
- Remove `allow_subdomains` from the role and try `api.inventory.svc` again.
- Revoke a certificate and find its serial number in the CRL.
- Issue a certificate before and after setting `config/urls`, and compare the two with `openssl x509 -text`.
