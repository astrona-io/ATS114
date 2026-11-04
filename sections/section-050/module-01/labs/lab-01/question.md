# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** TOTP

## Scenario

Release approvals need a second factor, and OpenBao should hold it. A partner also gave us the Base32 secret of their VPN authenticator, which is stored in the ConfigMap `partner-totp-secret` in the namespace `clients`, under the key `secret`. The TOTP secrets engine is not enabled yet.

## Your task

Connect with the lab-only root token (`kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d`) through the port-forward `kubectl -n openbao port-forward svc/openbao 8200:8200`, then:

1. Enable the TOTP secrets engine at its default path `totp/`.
2. Create a generated key `deploy-approval` with issuer `Inventory`, account name `release-manager`, algorithm `SHA256`, 8 digits and a period of 60 seconds.
3. Import the partner secret as the key `partner-vpn` with issuer `Partner` and account name `ops@partner.example`. Use the default algorithm, digits and period.
4. Create the policy `totp-validator`. A token with it may validate codes for `deploy-approval` and do nothing else.

## Constraints

- Do not enable the engine at another path.
- Do not give the policy the `read` capability.

## Done when

- `totp/keys/deploy-approval` shows the requested settings.
- `partner-vpn` produces the same codes as the partner secret.
- A token with `totp-validator` can validate a code for `deploy-approval` but cannot generate one or validate for other keys.
