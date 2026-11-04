# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** SSH

## Scenario

The operations team wants to stop copying public keys to servers. OpenBao should sign short-lived SSH certificates instead. The SSH secrets engine is not enabled yet. The public key of a test client is stored in the ConfigMap `ssh-client-key` in the namespace `clients`, under the key `public_key`.

## Your task

Connect with the lab-only root token (`kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d`) through the port-forward `kubectl -n openbao port-forward svc/openbao 8200:8200`, then:

1. Enable the SSH secrets engine at its default path `ssh/`.
2. Let OpenBao generate the CA signing key.
3. Create the role `deploy` for signed certificates. Only the principals `deploy` and `ops` are allowed, the default user is `deploy`, certificates live 30 minutes by default and 4 hours at most, and every certificate gets the extension `permit-pty`.
4. Sign the client public key through the role with the principal `deploy`, and try the principal `root`.

## Constraints

- Do not enable the engine at another path.
- Do not allow `*` or `root` as a principal.

## Done when

- `ssh/config/ca` returns a public key.
- The role `deploy` has the requested type, principals, lifetimes and extension.
- Signing the client key for `deploy` returns a certificate, and signing it for `root` is refused.
