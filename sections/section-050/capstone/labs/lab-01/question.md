# Question

Solve this question on: `terminal`

**Time:** about 40 minutes · **Topic:** SSH and TOTP

## Scenario

An audit of the OpenBao installation found three problems.

- The SSH role `ops` (engine `ssh/`) signs certificates for any principal, including `root`, and the certificates are valid for 720 hours.
- The Base32 secret of the TOTP key `prod-approval` (engine `totp/`) was pasted into a ticket. It is stored in the ConfigMap `leaked-totp-secret` in the namespace `clients`, under the key `secret`.
- Nobody has a narrow way to request SSH certificates. The public key of a test client is in the ConfigMap `ssh-client-key` in the same namespace, under the key `public_key`.

## Your task

Connect with the lab-only root token (`kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d`) through the port-forward `kubectl -n openbao port-forward svc/openbao 8200:8200`, then:

1. Restrict the role `ops`: only the principal `ops` is allowed and it is the default user, certificates live 15 minutes by default and 1 hour at most, and every certificate carries the critical option `source-address` with the value `10.0.0.0/8`. Keep the extension `permit-pty`.
2. Replace the key `prod-approval` with a new generated key with the same name, issuer `Inventory`, account name `prod`, algorithm `SHA256`, 8 digits and a period of 30 seconds. The leaked secret must not produce its codes.
3. Create the policy `ssh-signer`. A token with it may sign keys through the role `ops` and do nothing else.

## Constraints

- Do not disable or re-create the engines, and do not generate a new CA key.
- Do not give `ssh-signer` the `read` or `list` capability anywhere.

## Done when

- The role `ops` has exactly the requested principals, lifetimes and critical option.
- `prod-approval` has the requested settings, and a key built from the leaked secret gives different codes.
- A token with `ssh-signer` can sign the client key for `ops` through `ssh/sign/ops`, and cannot read `ssh/config/ca`, write roles or sign through another role.
