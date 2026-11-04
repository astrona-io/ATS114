# Issuers And Root Rotation In The PKI Engine

A root CA does not live forever. Its certificate has an expiry date, its key may need to change after a security review, and its name or key type may no longer meet policy. A PKI mount that only knows one CA cannot change without breaking every certificate it issued.

One PKI mount in OpenBao can hold several issuers. An issuer is one CA certificate with its private key. This module shows how to list and name issuers, choose which one signs new certificates, rotate a root to a new issuer while the old one still validates old certificates, and retire the old issuer safely.

This module has four parts. **Issuers And Keys** lists and names them. **The Default Issuer And Roles** chooses which issuer signs. **Rotating A Root CA** creates a new root next to the old one, and a graded lab follows it. **Retiring An Issuer** limits what the old issuer may do and removes it when it is no longer needed.

## Learning objectives

After this module you can:

- Explain what an issuer and a key are, and how they relate.
- List issuers and keys, and give them names.
- Set the default issuer and pin a role to an issuer with `issuer_ref`.
- Rotate a root CA with `pki/root/rotate/internal` without breaking old certificates.
- Limit an issuer with its `usage` field, and delete an issuer and its key.

## Before you start

You need a terminal with `jq` and `openssl`, and you should know what a CA certificate and a PKI role are. Your playground is a single-node `kind` cluster with **OpenBao v2.7.1** in the namespace `openbao`, already initialized and unsealed, with the `bao` command-line tool on your PATH. There is no PKI mount yet. The lab-only root token is in the Kubernetes Secret `openbao-init`.

Each part starts with the same short set-up: a port-forward in a second terminal and two environment variables, so `bao` knows the address and the token.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
