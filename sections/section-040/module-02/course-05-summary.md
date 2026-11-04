# Summary

Transit signs with keys it never reveals. The key type is fixed when it is created: `ed25519`, `ecdsa-p256`, `rsa-2048` and their larger forms can sign, and the default `aes256-gcm96` cannot. Input is Base64, and a signature starts with `vault:vN:`, where `vN` is the key version. A verify request returns `valid` as `true` or `false` and succeeds either way, so the caller must read the field.

New signatures use the latest key version and old signatures still verify after a rotation. The options `hash_algorithm`, `signature_algorithm`, `prehashed` and `marshaling_algorithm` must match between signer and verifier. HMAC uses a Transit key and a shared trust in OpenBao; the hash and random endpoints need no key.

Policies separate the operations, because each is its own path with the `update` capability. Keys should stay non-exportable, and backups should be treated as secrets. The key facts to remember are these:

- Create signing keys with a signing type.
- Check `valid`, not the HTTP status.
- Use one policy per role, such as signer and verifier.
- Do not mark keys exportable without a reason.

<!-- astrona:playground:destroy -->
