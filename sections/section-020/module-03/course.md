# Certificate Revocation, OCSP And Tidy In The PKI Engine

Issuing a certificate is half of the work of a certificate authority. The other half starts when a private key leaks, a service is removed, or thousands of expired certificates fill the storage. A CA that cannot revoke quickly, cannot tell clients about revocations, and cannot clean up after itself becomes a risk and a cost.

This module follows a certificate to its end. It revokes certificates and reads the certificate revocation list (CRL), configures how the CRL is built and published, enables the Online Certificate Status Protocol (OCSP) responder that answers one certificate at a time, and removes expired certificates from storage with tidy operations.

This module has four parts. **Revoking Certificates And Reading The CRL** revokes a certificate and shows what changes. **Configuring The CRL** sets its lifetime and rebuild behavior. **OCSP And The URLs In A Certificate** answers status requests and puts the right addresses into certificates. **Tidy And Auto-Tidy** removes expired data on request and on a schedule; a graded lab follows it.

## Learning objectives

After this module you can:

- Revoke a certificate by serial number and check the revocation time.
- Fetch the CRL and say when it changes.
- Configure `expiry`, `auto_rebuild` and delta CRLs with `pki/config/crl`.
- Ask the OCSP responder about a certificate with `openssl ocsp`.
- Set the URLs a certificate carries with `pki/config/urls`.
- Run `pki/tidy` and configure `pki/config/auto-tidy`.

## Before you start

You need a terminal with `jq` and `openssl`, and you should know how to issue a certificate from a PKI role. Your playground is a single-node `kind` cluster with **OpenBao v2.7.1** in the namespace `openbao`, already initialized and unsealed, with the `bao` command-line tool on your PATH. There is no PKI mount yet. The lab-only root token is in the Kubernetes Secret `openbao-init`.

Each part starts with the same short set-up: a port-forward in a second terminal and two environment variables, so `bao` knows the address and the token.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
