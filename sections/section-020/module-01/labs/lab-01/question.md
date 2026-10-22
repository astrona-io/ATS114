# Question

Solve this question on: `terminal`

**Time:** about 30 minutes · **Topic:** PKI

## Scenario

The inventory services `api.inventory.svc` and `web.inventory.svc` must talk to each other over TLS. The security team wants a private two-tier certificate authority in OpenBao, so that service certificates are short-lived and the root key is used only once.

## Your task

Connect with the lab-only root token (`kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d`) through the port-forward `kubectl -n openbao port-forward svc/openbao 8200:8200`, then build:

1. A **root CA** with the common name `Inventory Root CA`, valid for 10 years, in a PKI mount at `pki/`.
2. An **intermediate CA** with the common name `Inventory Intermediate CA`, valid for 5 years, in a PKI mount at `pki_int/`, signed by the root CA.
3. A role **`inventory-svc`** on `pki_int/` that issues certificates only for names under `inventory.svc`, for at most **72 hours**.
4. The issuing certificate URL `http://openbao.localtest.me:8200/v1/pki_int/ca` and the CRL URL `http://openbao.localtest.me:8200/v1/pki_int/crl` on `pki_int/`.

## Constraints

- Keep both CA private keys inside OpenBao.
- Service certificates must come from the intermediate CA only: no role on the root mount.

## Done when

- `pki/` serves a self-signed CA certificate named `Inventory Root CA`.
- `pki_int/` serves a CA certificate named `Inventory Intermediate CA`, signed by the root CA.
- A certificate for `api.inventory.svc` from `pki_int/issue/inventory-svc` verifies against the root and the intermediate with `openssl verify`, and a request for `www.example.com` is refused.
- The role allows subdomains of `inventory.svc` for at most 72 hours, and `pki/` has no role `inventory-svc`.
- The URL configuration of `pki_int/` holds both URLs.
