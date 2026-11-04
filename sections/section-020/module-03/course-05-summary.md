# Summary

A PKI mount stores the certificates it issues, and a serial number identifies each one. Revoking with `pki/revoke` sets a revocation time on the stored certificate and rebuilds the certificate revocation list, a signed list served without a token at `pki/crl`. Clients learn about a revocation only when they fetch the list again, so the `expiry` of the list sets the worst case. `pki/revoke-with-key` lets the holder of a certificate and its key revoke it, which also works for certificates that were not stored.

`pki/config/crl` controls the list. `expiry` is its validity, `auto_rebuild` rebuilds it before it expires, and delta CRLs add small frequent lists. The Online Certificate Status Protocol answers for one certificate: `good`, `revoked` or `unknown`. Certificates carry the addresses of the issuer, the CRL and the OCSP responder from `pki/config/urls`, but only if the URLs were set before the certificate was issued.

Tidy removes expired certificates and expired revocation entries. `pki/tidy` runs once, `pki/config/auto-tidy` runs on a schedule, and the `safety_buffer` keeps recent entries so that clients can still see them in the last CRL. The key facts to remember are these:

- Set the URLs before you issue certificates.
- Send every option you need in one write to a config path, and read it back.
- `auto_rebuild` stops the CRL from expiring on a quiet CA.
- Keep a safety buffer in tidy; do not set it near zero.

<!-- astrona:playground:destroy -->
