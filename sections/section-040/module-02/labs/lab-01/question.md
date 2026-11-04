# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** Transit

## Scenario

The release pipeline publishes the file `manifest.json`, stored in the ConfigMap `release-manifest` in the namespace `clients`. Deployment services must be able to check that the manifest was signed by the pipeline, but they must never be able to sign. The Transit engine is enabled at `transit/` and has no keys.

## Your task

Connect with the lab-only root token (`kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d`) through the port-forward `kubectl -n openbao port-forward svc/openbao 8200:8200`, then:

1. Create the Transit key `release-signing` of type `ed25519`.
2. Sign the exact content of `manifest.json` from the ConfigMap with that key, and store the signature in a new ConfigMap `release-signature` in the namespace `clients`, under the key `signature`.
3. Create the policy `release-verifier`. A token with it may verify with `release-signing` and do nothing else.

## Constraints

- Do not change the ConfigMap `release-manifest`.
- Do not make the key exportable.

## Done when

- `release-signing` is a non-exportable `ed25519` key.
- `transit/verify/release-signing` reports the stored signature as valid for the manifest.
- A token with `release-verifier` can verify, but cannot sign and cannot read the key settings.
