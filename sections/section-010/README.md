# Section 010: Static Secrets With KV Version 2

Most secrets an application needs are values someone already has: an API token from a partner, a password for a legacy system, a licence key. OpenBao keeps them in the KV (key/value) secrets engine. Version 2 of that engine does more than store them: it keeps a numbered version of every write, so a bad change or a deletion can be undone.

This section teaches the KV version 2 engine from the first write to the clean-up before an audit. It comes first because every other secrets engine builds on the same ideas: a mount, a path, a request with a token, and a response.

**Topic covered:** KV version 2

## What you will learn

- What a secrets engine and a mount are, and how KV version 2 lays out its paths (`data/` and `metadata/`).
- Writing, reading and patching secrets with `bao kv put`, `bao kv get` and `bao kv patch`.
- Reading older versions, and the difference between a soft delete, a destroy and an undelete.
- Restoring an older version with `bao kv rollback`.
- Limiting the number of versions per secret and for a whole mount.
- Protecting a secret from lost updates with check-and-set.

## The learning path

The modules start at their landing pages, which also launch their playgrounds. Each playground holds OpenBao, initialized and unsealed, with the engine of that module not set up yet.

### 1. Store And Version Secrets With KV Version 2

1. Secrets Engines And The KV Version 2 Engine
2. Versions, Deletes And Rollback
3. Metadata, Version Limits And Check-And-Set, followed by the lab **Recover A Secret After A Bad Write**
4. Patching, Listing, Custom Metadata And The API Paths
5. Summary

### 2. Manage Secrets Engine Mounts

1. Mounts, Paths And Engine Types
2. Tuning A Mount
3. Moving And Disabling Mounts, followed by the lab **Move And Tune Secrets Engine Mounts**
4. KV Version 1 And Upgrading To Version 2
5. Summary

### 3. Cubbyhole And Response Wrapping

1. The Cubbyhole Engine
2. Response Wrapping
3. Verifying A Wrapping Token, followed by the lab **Hand Over A Secret With Response Wrapping**
4. Wrapping Credentials From Other Engines
5. Summary

## Section capstone: Clean Up A KV Mount Before An Audit

The capstone is one graded scenario that combines the whole section. An auditor arrives tomorrow. One secret leaked a debug dump into its current version, another secret can be overwritten without warning, and the mount keeps every version for ever. Work it after the module labs.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS114.git -c sections/section-010/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-010/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-114-capstone-010
```
