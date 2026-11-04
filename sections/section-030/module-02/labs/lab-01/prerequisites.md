# Prerequisites

Before starting this lab you should be able to:

- Read a credential from `database/creds/<role>` and use its lease ID.
- Use `bao lease lookup`, `bao lease renew` and `bao lease revoke`.

## What the environment gives you

The lab environment builds itself before the task begins:

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- **OpenBao v2.7.1**, initialized and unsealed, in the namespace `openbao`, and the `bao` command-line tool on your PATH.
- The lab-only root token in the Secret `openbao-init` (key `root-token`). A real installation never keeps it there.
- **PostgreSQL 17** in the namespace `data`, database `inventory` with the table `items`. Lab-only users: `postgres` / `postgres-admin-password` (superuser) and `openbao_admin` / `openbao-admin-password`.

## Working rules

- Start the port-forward in a second terminal and leave it running: `kubectl -n openbao port-forward svc/openbao 8200:8200`.
- Everything is graded on the **final state** of OpenBao, so leave your fix in place.
- Change one thing at a time and check the result before the next change.
