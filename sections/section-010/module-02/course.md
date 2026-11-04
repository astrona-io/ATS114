# Manage Secrets Engine Mounts

The inventory team started with one KV mount and a few secrets. A year later there are mounts named `scratch`, `team-a-kv` and `old-reports`. Nobody remembers who owns them, one has the wrong maximum lease time, and the names no longer match the policies that grant access to them. The administrator must change this without losing data.

Every secrets engine in OpenBao lives at a path called a mount. This module shows how to list, enable, tune, move and disable mounts, and what each action does to the data, the leases and the policies that point at the mount. It ends with the difference between KV version 1 and version 2, because that choice is made when the mount is enabled.

This module has four parts. **Mounts, Paths And Engine Types** lists the mounts and enables new ones. **Tuning A Mount** changes lease limits, the description and the listing behavior. **Moving And Disabling Mounts** renames a mount and removes one, and a graded lab follows it. **KV Version 1 And Upgrading To Version 2** compares the two KV versions and upgrades a mount in place.

## Learning objectives

After this module you can:

- Explain what a mount is and read the mount table with `bao secrets list -detailed`.
- Enable an engine at a chosen path with a description and an engine version.
- Tune the default and maximum lease TTL of a mount, and say which limit applies.
- Move a mount to a new path and explain what the move changes.
- Disable a mount and explain what is destroyed.
- Tell KV version 1 from KV version 2 and upgrade a mount with `bao kv enable-versioning`.

## Before you start

You need a terminal and basic KV skills (`bao kv put` and `bao kv get`). Your playground is a single-node `kind` cluster with **OpenBao v2.7.1** in the namespace `openbao`, already initialized and unsealed, with the `bao` command-line tool on your PATH. It has only the built-in mounts. The lab-only root token is in the Kubernetes Secret `openbao-init`.

Each part starts with the same short set-up: a port-forward in a second terminal and two environment variables, so `bao` knows the address and the token.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
