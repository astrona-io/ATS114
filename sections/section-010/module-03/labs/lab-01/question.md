# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** Response wrapping

## Scenario

A new instance of the inventory application must receive the API key stored at `secret/inventory/api`, and nobody may paste the key into a chat message. A partner also sent the team its own API key as a wrapping token. The token is in the ConfigMap `received` in the namespace `clients` (key `token`), and the key is not stored anywhere else.

## Your task

Connect with the lab-only root token (`kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d`) through the port-forward `kubectl -n openbao port-forward svc/openbao 8200:8200`, then:

1. Create a wrapping token for the secret `secret/inventory/api` that is valid for 10 minutes, and store it in the key `token` of a new ConfigMap `delivery` in the namespace `clients`.
2. Unwrap the token in the ConfigMap `received`, and store the field `api-key` of its content in the field `api-key` of the KV secret `secret/inventory/partner`.

## Constraints

- Do not unwrap the token in `delivery`. The new instance must be able to do that.
- Do not print the content of `secret/inventory/api` to your terminal.

## Done when

- The ConfigMap `delivery` holds a valid, unused wrapping token whose creation path is `secret/data/inventory/api` and whose TTL is 600 seconds.
- `secret/inventory/partner` holds the partner API key in the field `api-key`.
- The wrapping token in `received` has been used.
