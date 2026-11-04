# Signing, Verifying And Hashing With The Transit Engine

Encryption keeps data secret. Signing proves where data came from and that nobody changed it. A release pipeline that signs its manifest, a service that verifies a webhook, and a system that needs a keyed hash all need the same thing: a key that never leaves a safe place and an operation that uses it. Transit provides all of these without handing the key to the caller.

This module uses Transit for signatures, message authentication codes, hashes and random bytes, and it describes how to control access and how to back up a key.

This module has four parts. **Signing Keys And Signatures** creates a signing key and signs data. **Verifying, Versions And Signature Options** checks signatures and explains how key rotation and algorithm options affect them. **HMAC, Hashing And Random Bytes** uses the other operations. **Access Control, Export And Backup** limits who can do what with a key and moves a key between clusters; a graded lab follows it.

## Learning objectives

After this module you can:

- Create an `ed25519`, `ecdsa-p256` or `rsa-2048` key and sign with it.
- Verify a signature and explain what changes after a key rotation.
- Use `hmac`, `hash` and `random`.
- Write separate policies for signing and verifying.
- Explain `exportable`, `allow_plaintext_backup`, backup and restore.

## Before you start

You need a terminal with `jq`. Your playground is a single-node `kind` cluster with **OpenBao v2.7.1** in the namespace `openbao`, already initialized and unsealed, with the `bao` command-line tool on your PATH. The Transit engine is not enabled yet. The lab-only root token is in the Kubernetes Secret `openbao-init`.

Each part starts with the same short set-up: a port-forward in a second terminal and two environment variables, so `bao` knows the address and the token.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
