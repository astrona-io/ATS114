# Summary

A time-based one-time password is computed from a shared secret and the current time. The time is divided by the period to give a counter, an HMAC of the counter is computed with the secret, and the result is cut down to a number with a fixed count of digits. The defaults, `SHA1`, 6 digits and 30 seconds, are the ones authenticator apps expect, and the settings cannot be changed after a key is created.

The TOTP engine holds keys that it generates with `generate=true` or imports with `url` or `key`. A generated key returns an `otpauth://` URL and a QR code once, unless `exported=false`. A read of `totp/code/<name>` generates the current code and a write with `code` validates one. A validation answer of `valid: false` is a normal response, and an accepted code is refused again in the same period.

Because generating and validating use different verbs on the same path, a policy can let a service validate with `update` and keep generation behind `read`. The key facts to remember are these:

- Show the URL and QR code once, and do not keep them.
- Read `valid`, not the status of the request.
- A validating service needs `update` only.
- Deleting a key invalidates every phone that holds it.

<!-- astrona:playground:destroy -->
