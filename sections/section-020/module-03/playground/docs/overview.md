# Overview: Certificate Revocation, OCSP And Tidy In The PKI Engine (Playground)

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

`new_cert` issues a certificate from the role `inventory-svc` and saves `leaf.pem` and `ca.pem` in the current directory. `ocsp_status` asks the OCSP responder about `leaf.pem`.

```sh
new_cert() {
  bao write -format=json pki/issue/inventory-svc common_name="$1".inventory.svc > issued.json
  jq -r '.data.certificate' issued.json > leaf.pem
  jq -r '.data.issuing_ca' issued.json > ca.pem
  jq -r '.data.serial_number' issued.json
}
ocsp_status() {
  openssl ocsp -issuer ca.pem -cert leaf.pem -url "$BAO_ADDR/v1/pki/ocsp" -CAfile ca.pem
}
```

Create the mount first: `bao secrets enable pki`, `bao secrets tune -max-lease-ttl=87600h pki`, a root with `pki/root/generate/internal`, and the role `inventory-svc`.

## Practice tasks

- Issue a certificate, check `ocsp_status`, revoke its serial, and check again.
- Read the CRL with `curl -s $BAO_ADDR/v1/pki/crl/pem | openssl crl -noout -text` before and after a revocation.
- Write `pki/config/crl` with only `expiry=1h` and read the other fields. What returned to defaults?
- Set `pki/config/urls`, issue a certificate, and read its extensions with `openssl x509 -in leaf.pem -noout -ext authorityInfoAccess,crlDistributionPoints`.
- Issue five certificates with `ttl=5m`, wait, run `pki/tidy` with `safety_buffer=1m`, and compare `bao list pki/certs` before and after.
- Enable `no_store=true` on a role, issue a certificate, and ask OCSP about it.
