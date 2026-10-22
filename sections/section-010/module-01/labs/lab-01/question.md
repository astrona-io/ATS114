# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** KV version 2

## Scenario

The inventory team keeps two secrets in the KV version 2 mount `secret/` of OpenBao. This morning a deployment script went wrong twice:

- It wrote a placeholder password into `inventory/db`. The application now fails to connect to its database.
- It deleted `inventory/api`, the token the application uses for a partner API.

Nobody remembers the real values. Both must come back from OpenBao itself.

## Your task

Connect with the lab-only root token (`kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d`) through the port-forward `kubectl -n openbao port-forward svc/openbao 8200:8200`, then:

1. Find the last good version of `inventory/db` and make its data the current version again.
2. Make `inventory/api` readable again, with the token it had before the deletion.
3. Limit `inventory/db` to at most **5** versions.

## Constraints

- Recover the values from OpenBao's history. Do not type the values in again with `bao kv put`.
- Do not delete and re-create either secret: the history of both must survive.

## Done when

- The current version of `inventory/db` holds the data of its last good version, as a new version.
- `inventory/api` is readable at its original version 1, with its original token.
- Both secrets still have their original version 1 in their history.
- The metadata of `inventory/db` shows `max_versions` as `5`.
