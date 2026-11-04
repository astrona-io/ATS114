# Summary

The connection holds the settings that apply to every role that uses it. `username_template` shapes the generated names with the role name, random characters and optional truncation, and PostgreSQL limits a name to 63 characters. `password_policy` names a password policy from `sys/policies/password/`, which sets the length and character rules; the policy can be tested with the generate endpoint. Both settings apply to new credentials only.

The role holds the SQL. The creation statements set the exact rights of the user and use the placeholders for the name, the password and the expiration. The revocation statements must take the grants back before they drop the user, or PostgreSQL refuses and the user stays. Rollback statements remove a partial creation.

A connection restricts its roles with `allowed_roles`, limits its pool with `max_open_connections`, `max_idle_connections` and `max_connection_lifetime`, and can be reset when the database restarted. The key facts to remember are these:

- Read the connection back after a change to confirm it.
- Put a random part in every username template.
- Revoke privileges before dropping a role.
- Avoid `allowed_roles="*"` in production.

<!-- astrona:playground:destroy -->
