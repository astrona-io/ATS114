# Question

Solve this question on: `terminal`

**Time:** about 30 minutes · **Topic:** KV version 2

## Scenario

An auditor reviews the KV version 2 mount `secret/` tomorrow. A quick look today found three problems:

- The current version of `inventory/db` contains a field `debug_dump` that a debugging script wrote by mistake. It must not be readable by anyone, ever again. The version before it was clean.
- `inventory/payments` can be overwritten by any writer without warning. Two scripts write to it, and last week one silently undid the other.
- No secret in the mount has a version limit, so every old value stays readable for ever.

## Your task

Connect with the lab-only root token (`kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d`) through the port-forward `kubectl -n openbao port-forward svc/openbao 8200:8200`, then:

1. Remove the leaked data of `inventory/db` so that it cannot be recovered, and make the clean data of the version before it the current version again.
2. Make every write to `inventory/payments` name the version it replaces.
3. Make the whole mount `secret/` keep at most **10** versions per secret by default.

## Constraints

- Do not delete and re-create either secret: their history must survive.
- Do not type the clean values in again by hand.

## Done when

- The leaked version of `inventory/db` shows `destroyed` as `true`.
- The current version of `inventory/db` holds the data of the clean version, without `debug_dump`, as a new version.
- `inventory/payments` requires check-and-set and still holds its `api_key`.
- The configuration of the mount `secret/` shows `max_versions` as `10`.
- Both secrets still have their original version 1.
