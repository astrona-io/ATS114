# Roles, Issuing Certificates And Revocation

An intermediate CA that signs anything is dangerous: a compromised application could ask it for a certificate for `bank.example.com`, and every client that trusts your root would believe it. The PKI engine therefore never issues a certificate directly. Every request goes through a role, and the role decides which names and lifetimes are allowed. This part writes a role, issues and checks certificates, and revokes one.

## Set up your terminal

The commands in this part need the root CA "Inventory Root CA" in the mount `pki/` and the signed intermediate "Inventory Intermediate CA" in `pki_int/`, as built in this module.

<!-- astrona:playground:renew -->

Start the port-forward in a second terminal and leave it running:

```sh
kubectl -n openbao port-forward svc/openbao 8200:8200
```

Then point `bao` at the server with the lab-only root token, and save both CA certificates for `openssl`:

```sh
export BAO_ADDR=http://openbao.localtest.me:8200
export BAO_TOKEN=$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)
curl -s $BAO_ADDR/v1/pki/ca/pem > root-ca.pem
curl -s $BAO_ADDR/v1/pki_int/ca/pem > intermediate-ca.pem
```

## Write a role

A PKI role is a named set of rules on one PKI mount. A request to `pki_int/issue/<role>` gets a certificate only if it fits the rules of that role. Create the role `inventory-svc` for the inventory services:

```sh
bao write pki_int/roles/inventory-svc \
    allowed_domains=inventory.svc allow_subdomains=true max_ttl=72h
```

The three fields do the main work:

| Field | Meaning |
| --- | --- |
| `allowed_domains` | The domains this role may issue names for |
| `allow_subdomains` | `true` lets the role issue names under those domains, such as `api.inventory.svc` |
| `max_ttl` | The longest lifetime a certificate from this role may have; here 72 hours |

The role lives on `pki_int/` only. There is no role on the root mount, so nobody can get a service certificate signed by the root.

## Issue and check a certificate

Ask the role for a certificate for `api.inventory.svc`, valid for one day, and keep the whole response in a file:

```sh
bao write -format=json pki_int/issue/inventory-svc \
    common_name=api.inventory.svc ttl=24h > api.json
jq -r '.data.certificate' api.json > api.pem
jq -r '.data.serial_number' api.json
```

The response holds the certificate, the CA chain, the serial number and a new private key. OpenBao does not store that private key: this response is the only copy, so the service must keep it. The last command prints the serial number, which you need to revoke the certificate later.

Check the certificate and its whole chain. The `-untrusted` file is the intermediate, which `openssl` uses to build the chain but does not trust on its own:

```sh
openssl x509 -in api.pem -noout -subject -issuer -dates
openssl verify -CAfile root-ca.pem -untrusted intermediate-ca.pem api.pem
```

The subject is `api.inventory.svc`, the issuer is `Inventory Intermediate CA`, and the dates span one day. `openssl verify` ends with `OK`: the certificate chains up to the root CA.

Now ask for a name the role does not allow:

```sh
bao write pki_int/issue/inventory-svc common_name=www.example.com
```

The PKI engine refuses the request with an error that the common name is not allowed by this role. This refusal is the whole point of a role.

## Put the URLs into certificates

A client that checks a certificate may want to download the issuing CA, or the list of revoked certificates. Certificates carry those addresses only if the mount is told what they are. Set them on the intermediate mount, issue a new certificate, and look for them:

```sh
bao write pki_int/config/urls \
    issuing_certificates="http://openbao.localtest.me:8200/v1/pki_int/ca" \
    crl_distribution_points="http://openbao.localtest.me:8200/v1/pki_int/crl"
bao write -field=certificate pki_int/issue/inventory-svc common_name=web.inventory.svc ttl=1h > web.pem
openssl x509 -in web.pem -noout -text | grep -A2 'CRL Distribution'
```

The certificate for `web.inventory.svc` now has a CRL distribution point that names `http://openbao.localtest.me:8200/v1/pki_int/crl`. Certificates issued before the change keep no URLs.

## Revoke a certificate

When a service's private key leaks, its certificate must stop being trusted before it expires. Revoke it by serial number, then read the certificate revocation list (CRL), a list of revoked serial numbers that the CA signs. Replace `<SERIAL>` with the serial number of `api.pem`, which you printed earlier:

```sh
bao write pki_int/revoke serial_number=<SERIAL>
curl -s $BAO_ADDR/v1/pki_int/crl/pem | openssl crl -noout -text | grep -i 'serial number'
```

The CRL now lists the serial number of `api.pem`. Revoked and expired certificates stay in the mount's storage until you tidy it. `bao write pki_int/tidy tidy_cert_store=true tidy_revoked_certs=true safety_buffer=72h` removes expired certificates that are older than 72 hours.

You can now limit what a CA signs with a role, issue certificates, check their chain, put the right URLs into them and revoke one. Together with the root and the intermediate, that is a complete internal CA.

## Common pitfalls

> [!WARNING]
> - **Writing the role on the root mount.** A role on `pki/` issues service certificates signed by the root, which is exactly what the intermediate exists to avoid.
> - **Expecting OpenBao to keep the private key.** The issue response is the only copy. If the service loses it, issue a new certificate.
> - **Setting the URLs after issuing.** Only certificates issued after `config/urls` carry the URLs.
> - **Forgetting `allow_subdomains`.** With only `allowed_domains=inventory.svc`, the role refuses `api.inventory.svc`.

## Your mission: Build A Two-Tier CA For The Inventory Services

You can now build a root CA and an intermediate, limit the intermediate with a role, and prove a certificate with `openssl`. The graded lab gives you an OpenBao with no PKI mounts and asks you to build the whole hierarchy for the inventory services, with a role that issues only names under `inventory.svc` for at most 72 hours, and the URLs set on the intermediate.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-114-playground-020-01
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS114.git -c sections/section-020/module-01/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-020/module-01/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-114-lab-020-01
astrona start ats-114-playground-020-01
```
