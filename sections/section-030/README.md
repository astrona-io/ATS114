# Section 030: Dynamic Database Credentials

A database password in a configuration file is a password that never changes, is shared by every copy of the application, and is still valid long after the person who saw it has left. The database secrets engine changes that: OpenBao creates a new database user for each request, gives it a lease, and drops the user when the lease ends or is revoked.

This section connects OpenBao to PostgreSQL and follows a dynamic credential through its whole life: created, used, renewed, revoked. It ends with the credentials OpenBao uses itself: its own connection password, which it can rotate so nobody else knows it, and static roles for users that must keep their name.

**Topic covered:** database engine and leases

## What you will learn

- The difference between a static and a dynamic secret, and what a lease is.
- Connecting the database secrets engine to PostgreSQL as a user that is not the superuser.
- Writing a role with SQL creation statements, a default lifetime and a maximum lifetime.
- Reading credentials, using them with `psql`, and looking up, renewing and revoking their lease.
- Revoking many leases at once with a prefix.
- Rotating the root credential, and static roles that rotate the password of an existing user.

## The learning path

The module starts at its landing page, which also launches the playground. The playground holds OpenBao, initialized and unsealed, and PostgreSQL 17 with the database `inventory`.

### 1. Generate Short-Lived Database Credentials

1. Dynamic Secrets And The Database Secrets Engine
2. Roles, Credentials And Their Leases, followed by the lab **Give The Inventory App Expiring Database Credentials**
3. Rotating The Root Credential And Static Roles
4. Summary

## Section capstone: Clean Up After A Database Credential Leak

The capstone is one graded scenario that combines the whole module. Four database credentials leaked into a build log, and the role that created them hands out leases of a month. Shorten the leases, revoke every leaked credential at once, and make sure the connection password that leaked with them stops working. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS114.git -c sections/section-030/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-030/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-114-capstone-030
```
