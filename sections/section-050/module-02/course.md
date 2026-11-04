# SSH Certificates And One-Time Passwords With The SSH Engine

Administrators and automation connect to servers over SSH. The usual way to allow it is to copy public keys into `authorized_keys` on every server, and then to forget to remove them. The SSH secrets engine replaces that with credentials that expire: a certificate authority that signs a user's public key for a short time, or a one-time password that works once.

This module configures the engine as a certificate authority, signs a key through a role with limits, and uses the one-time password mode. It also covers the server side: what a server must be told to trust.

This module has four parts. **Two Ways To Authenticate** explains the modes and sets up the engine. **Signing User Keys With A CA Role** creates a role and signs a key. **Restricting A Role** limits principals, lifetime and extensions. **One-Time Passwords** uses the second mode; a graded lab follows it.

## Learning objectives

After this module you can:

- Choose between signed certificates and one-time passwords.
- Generate the CA key and read its public key.
- Write a CA role and sign a public key with it.
- Read a certificate with `ssh-keygen -L` and explain its fields.
- Limit principals, TTL, extensions and critical options on a role.
- Create and verify a one-time password.

## Before you start

You need a terminal with `jq` and `ssh-keygen`. Your playground is a single-node `kind` cluster with **OpenBao v2.7.1** in the namespace `openbao`, already initialized and unsealed, with the `bao` command-line tool on your PATH. The SSH engine is not enabled yet. The lab-only root token is in the Kubernetes Secret `openbao-init`.

Each part starts with the same short set-up: a port-forward in a second terminal and two environment variables, so `bao` knows the address and the token.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
