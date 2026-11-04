# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** Mounts

## Scenario

The inventory team keeps its application secrets in a KV version 2 mount named `scratch/`. The name was meant to be temporary, and the policies that the team writes next week will use `apps/`. A second mount, `old-reports/`, has been unused for a year. The mount `scratch/` holds the secret `report/q1` and has no lease limits of its own.

## Your task

Connect with the lab-only root token (`kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d`) through the port-forward `kubectl -n openbao port-forward svc/openbao 8200:8200`, then:

1. Rename the mount `scratch/` to `apps/` so that the secret `report/q1` is still readable.
2. Set on `apps/` a default lease TTL of 1 hour, a maximum lease TTL of 24 hours and the description `Application secrets`.
3. Remove the unused mount `old-reports/`.

## Constraints

- Do not read the secret out and write it again by hand. The data must move with the mount.
- Do not disable `scratch/` or `apps/`.

## Done when

- A KV mount exists at `apps/` and `scratch/` does not exist.
- `report/q1` in `apps/` still has `owner` set to `finance`.
- `apps/` has the lease limits and the description from step 2.
- `old-reports/` does not exist.
