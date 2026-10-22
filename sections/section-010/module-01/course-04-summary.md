# Summary

OpenBao stores nothing until you enable a secrets engine at a mount. The KV version 2 engine stores key/value secrets and keeps a numbered version of every write. Each secret has two paths: its data under `<mount>/data/` and its history and settings under `<mount>/metadata/`. The `bao kv` commands add those path parts for you, but policies and the HTTP API always use the full paths.

`bao kv put` replaces a whole secret and `bao kv patch` changes only the fields you name; both create a new version. Any older version stays readable with `-version`, and `bao kv metadata get` shows the whole history. A bad write is undone with `bao kv rollback`, which copies an older version into a new current version and keeps the bad one in the history.

Removing data comes in three strengths. A soft delete with `bao kv delete` marks a version deleted and can be undone with `bao kv undelete`, which brings back the same version number. A destroy with `bao kv destroy` removes the data of a version for good, which is the right answer when a version leaked. Deleting the metadata removes the whole secret with all its versions.

The metadata also controls the history. `max_versions` limits how many versions a secret keeps and is applied on the next write; the mount configuration at `<mount>/config` sets a default for every secret. `delete_version_after` soft-deletes new versions after a set time. With `cas_required`, every write must name the version it replaces, so two writers cannot silently undo each other. The key facts to remember are these:

- Recover with `rollback` and `undelete`; never type a lost value in again by hand.
- A leaked version must be destroyed, not deleted.
- `secret/data/...` holds values, `secret/metadata/...` holds history and settings.
- `-cas=0` writes only when the secret does not exist yet.

<!-- astrona:playground:destroy -->
