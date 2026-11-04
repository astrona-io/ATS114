# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** PKI

## Scenario

The security team wants the root CA of the inventory services replaced. The PKI mount `pki/` has one root issuer named `inventory-root-1` and the role `inventory-svc`, which issues certificates for names under `inventory.svc`. Every client already trusts the new root, so the mount can start signing with it. Certificates that the old root issued must stay valid.

## Your task

Connect with the lab-only root token (`kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d`) through the port-forward `kubectl -n openbao port-forward svc/openbao 8200:8200`, then:

1. Add a new root issuer to `pki/` named `inventory-root-2` with the common name `Inventory Root CA 2` and its own key.
2. Make `inventory-root-2` the default issuer, so `pki/issue/inventory-svc` is signed by it.
3. Stop `inventory-root-1` from issuing certificates, but let it keep signing revocation lists.

## Constraints

- Do not delete the issuer `inventory-root-1` or its key.
- Do not change the role `inventory-svc`.

## Done when

- `inventory-root-2` is the default issuer and a certificate from `inventory-svc` has it as issuing CA.
- `inventory-root-1` exists, has its key, and its `usage` has `crl-signing` but not `issuing-certificates`.
