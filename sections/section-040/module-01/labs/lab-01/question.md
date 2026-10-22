# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** Transit

## Scenario

The inventory application encrypts its order notes with the Transit key `inventory-records` and stores the ciphertext in the ConfigMap `encrypted-records` in the namespace `clients`, one record per key (`record-a`, `record-b`, `record-c`). The key was rotated twice over the last months, but nobody updated the stored records. The security team now wants every record on the newest key version, and the older versions retired so they can never decrypt again.

## Your task

Connect with the lab-only root token (`kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d`) through the port-forward `kubectl -n openbao port-forward svc/openbao 8200:8200`, then:

1. Find which key version each stored record uses, and which version is the newest.
2. Move every record in `encrypted-records` to the newest key version, and store the new ciphertext in the ConfigMap.
3. Make sure only the newest key version of `inventory-records` can decrypt.

## Constraints

- Every record must still decrypt to exactly the text it had before.
- Do not delete or re-create the key `inventory-records`.

## Done when

- Every record in `encrypted-records` starts with the prefix of the newest key version.
- Every record decrypts to its original text.
- The key's `min_decryption_version` equals its `latest_version`.
