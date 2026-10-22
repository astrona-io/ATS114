# Question

Solve this question on: `terminal`

**Time:** about 45 minutes · **Topic:** Transit, KV and database leases

## Scenario

A debug backup of the inventory system was found on a public file share. It contained three things that are now treated as leaked:

- The current version of the KV secret `inventory/db` in the mount `secret/`, which carries an extra field `debug_dump`. The version before it was clean.
- The first version of the Transit key `inventory-records`. Both records in the ConfigMap `encrypted-records` (namespace `clients`) are encrypted with it.
- Four credentials from the database role `inventory-readonly`, together with the password of the connection user `openbao_admin`.

PostgreSQL runs in the namespace `data`; the lab-only superuser is `postgres` with the password `postgres-admin-password`.

## Your task

Connect with the lab-only root token (`kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d`) through the port-forward `kubectl -n openbao port-forward svc/openbao 8200:8200`, then:

1. Remove the leaked KV version of `inventory/db` so it cannot be recovered, and make the clean data of the version before it current again.
2. Retire the leaked Transit key version: give `inventory-records` a new version, move both stored records to it, and make sure the leaked version can no longer decrypt.
3. Revoke every credential the database role `inventory-readonly` has handed out, and make sure the leaked password of `openbao_admin` stops working while OpenBao keeps creating credentials.

## Constraints

- Do not delete and re-create the secret, the Transit key, or the database connection.
- Every stored record must still decrypt to its original text.

## Done when

- Version 2 of `inventory/db` is destroyed, and the current version holds the data of version 1, without `debug_dump`.
- Both records use the newest version of `inventory-records`, decrypt to their original text, and `min_decryption_version` equals `latest_version`.
- None of the four leaked leases or their database users exists any more.
- `openbao_admin` no longer accepts `openbao-admin-password`, and a new credential from `inventory-readonly` still works.
