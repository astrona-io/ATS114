# Summary

A lease is the record of a secret that OpenBao can end. A read from `database/creds/<role>` returns `lease_id`, `lease_duration` and `renewable`, and `bao lease lookup` shows the issue time, the expiry and the remaining TTL. Static secrets such as KV version 2 carry no lease. The lease is what lets OpenBao run the revocation statements and drop the database user.

A renewal asks for a lease time counted from now, with `-increment`. OpenBao grants up to the nearest limit: the role's `max_ttl`, measured from creation, or the `max-lease-ttl` of the mount. A renewal never moves `max_ttl`, and a mount limit does not shorten existing leases. Leases are listed with `sys/leases/lookup/<prefix>`, revoked one at a time with `bao lease revoke`, and revoked in bulk with `-prefix`. `-force` removes lease entries even when the database work fails, and leaves the users behind.

A lease belongs to the token that created it. Revoking or losing the token revokes its leases. An application should renew at about half of the duration, read a new credential when renewal fails or `max_ttl` is reached, and revoke on shutdown. The key facts to remember are these:

- Keep the lease ID with the credential.
- The shortest limit always wins.
- Use the longest prefix that covers an incident.
- Force removes entries, not database users.

<!-- astrona:playground:destroy -->
