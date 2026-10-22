# Summary

The PKI secrets engine turns OpenBao into a certificate authority. A CA is a key and a certificate that signs other certificates; clients trust the CA, so they trust what it signs. OpenBao keeps the CA keys inside its storage when you generate them with `internal`, so no key file ever leaves the server.

The usual hierarchy has two tiers. The root CA lives in its own mount, gets a long lifetime after `bao secrets tune -max-lease-ttl`, and signs nothing but intermediate CAs. The intermediate CA lives in a second mount: OpenBao generates its key and a certificate signing request, the root signs that request with `root/sign-intermediate`, and `intermediate/set-signed` installs the signed certificate. If the intermediate key ever leaks, the root revokes it and signs a new one, and clients keep the root they already trust.

Certificates come only through roles. A role on the intermediate mount names the allowed domains, whether subdomains are allowed, and the longest lifetime. A request outside those rules is refused. Each issue response holds a new private key that OpenBao does not store, so the service must keep it. `openssl verify` with the root as the trusted CA and the intermediate as an untrusted helper proves that a certificate chains up to the root.

A CA also needs a way to take trust back. `config/urls` puts the issuing CA and CRL addresses into every certificate issued after the change. Revoking a serial number adds it to the certificate revocation list, which, like the CA certificates, anyone can download without a token. The key facts to remember are these:

- Tune the mount's maximum lease time before you generate a CA.
- The root signs only intermediates; roles live on the intermediate mount.
- A role refuses every name and lifetime it does not allow.
- The issue response is the only copy of the private key.

<!-- astrona:playground:destroy -->
