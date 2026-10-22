# Store And Version Secrets With KV Version 2

An application team writes a new database password to OpenBao, and the application stops working. The new password has a typo. With a plain key/value store, the old password is gone and someone has to reset it in the database. With KV version 2, the old password is still there as version 2, and one command makes it current again.

The KV secrets engine stores key/value pairs at paths. A secrets engine is a component OpenBao enables at a path, called a mount, that stores, creates or encrypts data. **KV version 2 keeps a numbered version of every write**, and it separates the data of a secret from its metadata: the version history and the settings.

This module has three parts. **Secrets Engines And The KV Version 2 Engine** enables the engine and writes, reads and patches a first secret. **Versions, Deletes And Rollback** reads older versions and shows the three ways to remove data: a soft delete, a destroy, and deleting the metadata. **Metadata, Version Limits And Check-And-Set** changes how many versions a secret keeps and protects it from lost updates. A graded lab follows the third part.

## Learning objectives

After this module you can:

- Explain what a secrets engine and a mount are.
- Enable KV version 2 and name its `data/` and `metadata/` paths.
- Write, read and patch a secret, and read any older version.
- Explain the difference between a soft delete, a destroy and deleting the metadata.
- Undelete a version and roll back to an older version.
- Set `max_versions`, `delete_version_after` and `cas_required` on a secret and on a mount.
- Write with check-and-set and explain the error when the version is wrong.

## Before you start

You need Kubernetes basics (`kubectl get`, `kubectl exec`, `kubectl port-forward`) and a terminal with `jq`. You should know that OpenBao must be unsealed before it answers, and that every request carries a token.

Your playground is a single-node `kind` cluster with **OpenBao v2.7.1** in the namespace `openbao`, already initialized and unsealed, and the `bao` command-line tool on your PATH. Nothing is enabled yet: you enable the KV engine yourself in the first part. The lab-only root token is in the Kubernetes Secret `openbao-init`; the parts read it from there.

Each part starts with the same short set-up: a port-forward in a second terminal, so your machine reaches OpenBao, and two environment variables, so `bao` knows the address and the token.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
