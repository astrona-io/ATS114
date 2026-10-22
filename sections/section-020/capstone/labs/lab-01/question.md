# Question

Solve this question on: `terminal`

**Time:** about 35 minutes · **Topic:** PKI

## Scenario

Someone started the inventory certificate authority last week and was moved to another team half-way. The root CA `Inventory Root CA` in `pki/` is fine, and every client in the company already trusts it. Everything after that is broken:

- Services that ask `pki_int/issue/inventory-svc` for a certificate get an error.
- The role `inventory-svc` on `pki_int/` was written for the wrong domain.
- A role `inventory-svc` was also created on the root mount `pki/` "to test something".
- Certificates carry no address where clients can find the revocation list.

## Your task

Connect with the lab-only root token (`kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d`) through the port-forward `kubectl -n openbao port-forward svc/openbao 8200:8200`, find out why each part fails, and repair the hierarchy:

1. Make `pki_int/` a working intermediate CA named `Inventory Intermediate CA`, signed by the existing root.
2. Make the role `inventory-svc` on `pki_int/` issue certificates only for names under `inventory.svc`, for at most **72 hours**.
3. Make sure service certificates cannot come from the root mount.
4. Make new certificates from `pki_int/` carry the CRL URL `http://openbao.localtest.me:8200/v1/pki_int/crl` (and the issuing certificate URL `http://openbao.localtest.me:8200/v1/pki_int/ca`).

## Constraints

- Keep the existing root CA. Clients already trust it; a new root would break them all.
- Keep the CA private keys inside OpenBao.

## Done when

- The root CA certificate in `pki/` is the one that existed when the capstone started.
- `pki_int/` serves `Inventory Intermediate CA`, signed by `Inventory Root CA`.
- A certificate for `api.inventory.svc` verifies against the chain, and `www.example.com` is refused.
- The role on `pki_int/` is correct, and `pki/` has no role `inventory-svc`.
- A new certificate from `pki_int/` names `http://openbao.localtest.me:8200/v1/pki_int/crl` as its CRL distribution point.
