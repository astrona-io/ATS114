# Prerequisites

Before starting this lab you should be able to:

- Configure the database secrets engine and a role.
- Renew, revoke and look up leases with `bao lease`.
- Explain why OpenBao rotates its own connection password.

## What the environment gives you

The lab environment builds itself before the task begins:

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- **OpenBao v2.7.1**, initialized and unsealed, in the namespace `openbao`, and the `bao` command-line tool on your PATH.
- The lab-only root token in the Secret `openbao-init` (key `root-token`). A real installation never keeps it there.
- **PostgreSQL 17** in the namespace `data`, with the database `inventory` and the users `postgres` and `openbao_admin`.

## Working rules

- Start the port-forward in a second terminal and leave it running: `kubectl -n openbao port-forward svc/openbao 8200:8200`.
- Everything is graded on the **final state** of OpenBao and PostgreSQL, so leave your fix in place.
- Change one thing at a time and check the result before the next change.
