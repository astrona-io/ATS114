# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** PKI

## Scenario

A private key of the inventory service `leaked.inventory.svc` was exposed. The PKI mount `pki/` has a root CA, the role `inventory-svc`, and two issued certificates: `healthy.inventory.svc` and the leaked one. The serial number of the leaked certificate is in the ConfigMap `compromised-cert` in the namespace `openbao`, under the key `serial`. The mount still has its default CRL, URL and tidy settings. Clients reach OpenBao at `http://openbao.localtest.me:8200`.

## Your task

Connect with the lab-only root token (`kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d`) through the port-forward `kubectl -n openbao port-forward svc/openbao 8200:8200`, then:

1. Revoke the leaked certificate by its serial number.
2. Make the CRL valid for 24 hours and rebuild it automatically 6 hours before it expires. Keep the OCSP responder enabled.
3. Set the OCSP address that new certificates carry to `http://openbao.localtest.me:8200/v1/pki/ocsp`, and the issuer and CRL addresses to `http://openbao.localtest.me:8200/v1/pki/ca` and `http://openbao.localtest.me:8200/v1/pki/crl`.
4. Turn on automatic tidy that runs every 12 hours, removes expired certificates and expired revoked certificates, and keeps a safety buffer of 72 hours.

## Constraints

- Do not revoke `healthy.inventory.svc`.
- Do not disable the CRL or the OCSP responder.

## Done when

- The leaked certificate has a revocation time and no other certificate is revoked.
- `pki/config/crl` has `expiry` of `24h`, `auto_rebuild` of `true` and `ocsp_disable` of `false`.
- `pki/config/urls` has the OCSP address, and `pki/config/auto-tidy` is enabled with the options above.
