# Prerequisites

Before starting this lab you should be able to:

- Read and write secrets with `bao kv get` and `bao kv put`.
- Explain the difference between a soft delete and a destroy in KV version 2.
- Read the version history of a secret with `bao kv metadata get`.

## What the environment gives you

The lab environment builds itself before the task begins:

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- **OpenBao v2.7.1**, initialized and unsealed, in the namespace `openbao`, and the `bao` command-line tool on your PATH.
- The lab-only root token in the Secret `openbao-init` (key `root-token`). A real installation never keeps it there.

## Working rules

- Start the port-forward in a second terminal and leave it running: `kubectl -n openbao port-forward svc/openbao 8200:8200`.
- Everything is graded on the **final state** of OpenBao, so leave your fix in place.
- Change one thing at a time and check the result before the next change.
