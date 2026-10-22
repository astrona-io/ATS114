# Encrypt Data With The Transit Engine

The inventory application stores order notes in a table, and some notes hold customer details. The team must encrypt them, but nobody wants an encryption key in the application's configuration, where every copy of the application and every backup of the configuration would hold it.

The Transit secrets engine encrypts and decrypts on request. The application sends plaintext and gets ciphertext back, stores the ciphertext itself, and sends it back later to decrypt. **The key never leaves OpenBao, and OpenBao never stores the data**, so a leaked database without OpenBao is only ciphertext.

This module has two parts. **Encryption As A Service** creates a key, encrypts and decrypts records, reads the ciphertext format and uses a data key. **Key Rotation, Rewrap And Retiring Old Versions** rotates the key, moves stored ciphertext to the new version without decrypting it, and stops old versions from decrypting. A graded lab follows the second part.

## Learning objectives

After this module you can:

- Explain what encryption as a service is and what Transit stores.
- Create a named key and read its type and versions.
- Encrypt and decrypt data, including the Base64 step on both sides.
- Read which key version a ciphertext uses from its `vault:vN:` prefix.
- Explain when to use a data key.
- Rotate a key, rewrap ciphertext, and set `min_decryption_version`.

## Before you start

You need Kubernetes basics and a terminal with `jq` and `base64`. You should know the difference between plaintext and ciphertext.

Your playground is a single-node `kind` cluster with **OpenBao v2.7.1** in the namespace `openbao`, already initialized and unsealed, and the `bao` command-line tool on your PATH. There is no Transit mount yet: you enable it in the first part. The lab-only root token is in the Kubernetes Secret `openbao-init`.

Each part starts with the same short set-up: a port-forward in a second terminal, so your machine reaches OpenBao, and two environment variables, so `bao` knows the address and the token.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
