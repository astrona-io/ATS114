# Time-Based One-Time Passwords With The TOTP Engine

A one-time password from an authenticator app is the second factor behind many logins. OpenBao can play either side of that exchange: it can act as the authenticator app and produce codes for a secret it holds, or it can act as the server and check codes that a person's app produces. The TOTP secrets engine does both, so an internal service does not need its own library or its own place to store the secrets.

This module explains how a time-based code is made, creates keys in both modes, generates and validates codes, and restricts who may do which.

This module has four parts. **How TOTP Works** explains the algorithm and creates a key. **Generating And Validating Codes** produces and checks codes. **Provider And Consumer Modes** imports an existing secret and uses the export setting. **Access Control And Operations** separates generating from validating in policies; a graded lab follows it.

## Learning objectives

After this module you can:

- Explain how the secret, the time and the settings produce a code.
- Create a TOTP key with `generate=true` and read its settings.
- Generate a code and validate a code.
- Import an existing key from a URL or a Base32 secret.
- Write a policy that lets a service validate codes but not generate them.

## Before you start

You need a terminal with `jq`. Your playground is a single-node `kind` cluster with **OpenBao v2.7.1** in the namespace `openbao`, already initialized and unsealed, with the `bao` command-line tool on your PATH. The TOTP engine is not enabled yet. The lab-only root token is in the Kubernetes Secret `openbao-init`.

Each part starts with the same short set-up: a port-forward in a second terminal and two environment variables, so `bao` knows the address and the token.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
