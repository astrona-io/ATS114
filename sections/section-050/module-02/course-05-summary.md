# Summary

The SSH engine replaces permanent public keys with credentials that expire. In certificate mode, OpenBao holds a CA key that never leaves it, and a role signs a user's public key with a limited lifetime. Servers trust the CA public key once through `TrustedUserCAKeys`, and the certificate names the principals that may log in. `ssh-keygen -L` shows what a certificate contains.

A role sets the limits: `allowed_users` for principals, `ttl` and `max_ttl` for the lifetime, and extensions and critical options for abilities and restrictions. Using `*` for allowed users, and wide TTLs, are the common mistakes, because a certificate cannot easily be revoked.

In one-time password mode, `ssh/creds/<role>` returns a password for one address. A helper on the server verifies it at `ssh/verify`, and OpenBao deletes it after the first use. The mode needs a call to OpenBao at each login and a helper on each server. The key facts to remember are these:

- Generate the CA key inside OpenBao.
- List exact principals; never `*`.
- Keep `max_ttl` short.
- Use OTP only for servers that cannot use certificates.

<!-- astrona:playground:destroy -->
