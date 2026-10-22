# Run An Internal Certificate Authority With The PKI Engine

The inventory team runs several services inside the cluster, such as `api.inventory.svc` and `web.inventory.svc`, and they must talk to each other over TLS. Each service needs a certificate that the others trust, and that certificate should expire in days, not years. Doing that by hand with `openssl` for every service does not scale.

The PKI secrets engine makes OpenBao a certificate authority. A certificate authority (CA) is a key and a certificate that signs other certificates; anyone who trusts the CA trusts what it signs. **OpenBao keeps the CA keys inside its storage and signs certificates on request, through a role that limits what each request may get.**

This module has three parts. **The PKI Engine And A Root CA** enables the engine and creates the root CA. **An Intermediate CA Signed By The Root** creates a second CA, has the root sign it, and explains why the root should sign nothing else. **Roles, Issuing Certificates And Revocation** limits names and lifetimes with a role, issues and checks certificates, sets the URLs certificates carry, and revokes one. A graded lab follows the third part.

## Learning objectives

After this module you can:

- Explain what a root CA, an intermediate CA, a CSR and a certificate chain are.
- Enable the PKI engine at a path and set its maximum lease time.
- Generate a root CA whose private key never leaves OpenBao.
- Sign an intermediate CA with the root and install the signed certificate.
- Write a role that limits names and lifetimes, and issue a certificate from it.
- Check a certificate and its chain with `openssl`.
- Set the issuing certificate and CRL URLs, revoke a certificate and read the CRL.

## Before you start

You need Kubernetes basics and a terminal with `jq` and `openssl` (on macOS, the built-in `openssl` is enough for these pages). You should know what a TLS certificate is: a public key with a name, signed by someone.

Your playground is a single-node `kind` cluster with **OpenBao v2.7.1** in the namespace `openbao`, already initialized and unsealed, and the `bao` command-line tool on your PATH. There are no PKI mounts yet: you create them in the parts. The lab-only root token is in the Kubernetes Secret `openbao-init`.

Each part starts with the same short set-up: a port-forward in a second terminal, so your machine reaches OpenBao, and two environment variables, so `bao` knows the address and the token.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
