# Summary

The cubbyhole engine gives every token a private key/value store at `cubbyhole/`. The same path leads to a different store for each token, no policy can open the store of another token, and OpenBao deletes the store when the token expires or is revoked.

Response wrapping uses that store. When a request carries a wrap TTL, OpenBao writes the response into the cubbyhole of a new single-use token and returns only that wrapping token. `bao unwrap` returns the original response and deletes the token, so a second unwrap fails. A failed unwrap means that the token expired or that someone used it first, and the safe reaction is to treat the secret as exposed and send a new one.

Before unwrapping, the receiver can call `sys/wrapping/lookup`, which needs no token and does not consume the wrapping token, and compare the creation path with the expected one. Wrapping works for static secrets, tokens, database credentials and certificates, and a policy can force it with `min_wrapping_ttl` and `max_wrapping_ttl`. The key facts to remember are these:

- A wrapping token works once; a failed unwrap is a warning.
- Look up the creation path before you unwrap.
- Only the wrapping token travels between people.
- A wrapped dynamic credential is already valid, so its lease is running.

<!-- astrona:playground:destroy -->
