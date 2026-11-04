# Summary

A PKI mount stores issuers and keys as separate objects. An issuer is a CA certificate, a key is the private key behind it, and an issuer points to its key with `key_id`. A reference to either can be an ID, a name or `default`, and giving names at creation with `issuer_name` and `key_name` makes scripts readable.

When a mount holds more than one issuer, the default issuer signs every request that does not name another, and `pki/config/issuers` changes the default. A role can pin an issuer with `issuer_ref`. A root rotation creates a new root with `pki/root/rotate/internal`, puts the new certificate into every trust store, makes the new issuer the default, and only then retires the old one.

Retiring is done in stages. Removing `issuing-certificates` from the `usage` field of the old issuer stops it from signing certificates but keeps its revocation list and its certificate. Deleting the issuer and then its key finishes it, and must wait until no valid certificate depends on the issuer. The key facts to remember are these:

- Trust the new root first, switch the default second.
- A role with `issuer_ref` ignores the default.
- Limit with `usage` before you delete.
- Delete the issuer first, then its key.

<!-- astrona:playground:destroy -->
