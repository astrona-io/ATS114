# Summary

A static secret is a value someone stored; OpenBao can hand it out but cannot take it back. A dynamic secret is a value OpenBao creates at the moment of the request, in a system it controls, and every dynamic secret has a lease: an ID, a duration and a renewable flag. When the lease ends or is revoked, OpenBao cleans up in the target system.

The database secrets engine applies this to databases. A connection holds the plugin, the connection URL with `{{username}}` and `{{password}}` placeholders, the roles allowed to use it, and the root credential OpenBao connects with. That user should be able to create users and grant them access, and nothing more; it should never be the database superuser. OpenBao never shows the connection password again once it is written.

A role turns a request into a user. Its creation statements are SQL with `{{name}}`, `{{password}}` and `{{expiration}}`, and they are the only place where the new user's rights are set. `default_ttl` is the lease a new credential gets and `max_ttl` the longest it can live with renewals. Reading `database/creds/<role>` creates a user and returns its lease ID; `bao lease lookup`, `bao lease renew` and `bao lease revoke` manage it from then on, and a revoked or expired lease drops the user.

Two kinds of rotation protect the long-lived users. `rotate-root` sets a new password for the connection user that only OpenBao knows, so the password a person once typed stops working. A static role maps one existing user to OpenBao and rotates its password on a schedule, with no lease, for tools that must keep their user name. The key facts to remember are these:

- Revoking a lease drops the database user at once.
- `-prefix` revokes every lease under a path, for example all credentials of one role.
- A renewal never takes a lease past `max_ttl`.
- After `rotate-root`, only OpenBao can log in as the connection user.

<!-- astrona:playground:destroy -->
