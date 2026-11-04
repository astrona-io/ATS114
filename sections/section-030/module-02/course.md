# Lease Management For Database Credentials

Every dynamic credential that OpenBao hands out comes with a lease. The lease is the record that lets OpenBao end the credential: renew it while an application still needs it, and revoke it when it does not. An operator who cannot read, renew, list and revoke leases cannot respond to an incident, a leaked credential or an application that creates too many users.

This module works with leases on the database engine, but the same lease commands and rules apply to every engine that returns dynamic secrets. It reads what a lease contains, renews it within its limits, finds leases that you did not create yourself, revokes one lease or all leases of a role, and describes how leases relate to the token that created them.

This module has four parts. **Anatomy Of A Lease** reads the fields and looks one up. **Renewing And The TTL Limits** extends a lease and shows which limit stops it. **Listing And Revoking Leases** ends one lease or many. **Leases, Tokens And Application Patterns** shows what happens to leases when a token ends, and how an application should handle them; a graded lab follows it.

## Learning objectives

After this module you can:

- Name the fields of a lease and look a lease up.
- Renew a lease and explain the roles of `default_ttl`, `max_ttl` and the mount limits.
- List the leases under a role.
- Revoke one lease, or every lease under a prefix.
- Explain what happens to leases when the token that created them is revoked.
- Describe how an application should renew and replace credentials.

## Before you start

You need a terminal with `jq`. Your playground is a single-node `kind` cluster with **OpenBao v2.7.1** in the namespace `openbao`, already initialized and unsealed, and **PostgreSQL 17** in the namespace `data`. The lab-only root token is in the Kubernetes Secret `openbao-init`. The database engine is not enabled yet; the first part enables it.

Each part starts with the same short set-up: a port-forward in a second terminal and two environment variables, so `bao` knows the address and the token.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
