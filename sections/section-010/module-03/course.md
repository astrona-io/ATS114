# Cubbyhole And Response Wrapping

A new application instance needs an API key, and someone has to hand it over. If the administrator pastes the key into a chat message or a ticket, the key is now in a log that many people can read, and nobody can tell whether it was used by someone else first.

Response wrapping solves this. OpenBao stores the response in a private place that only a single-use wrapping token can open. The administrator passes only the wrapping token. The first party that unwraps it gets the secret, and a second attempt fails, so a stolen token is detected. The private place is the cubbyhole engine, which this module explains first.

This module has four parts. **The Cubbyhole Engine** shows the private store that each token has. **Response Wrapping** wraps and unwraps a response. **Verifying A Wrapping Token** checks where a token came from before it is used, and explains what a failed unwrap means. **Wrapping Credentials From Other Engines** wraps database and KV responses and limits the lifetime a caller may ask for. A graded lab follows the third part.

## Learning objectives

After this module you can:

- Explain what the cubbyhole engine stores and who can read it.
- Wrap a response with `-wrap-ttl` and unwrap it with `bao unwrap`.
- Explain why a wrapping token can be used once.
- Look up a wrapping token with `sys/wrapping/lookup` and check its creation path.
- Say what it means when an unwrap fails.
- Limit wrapping lifetimes in a policy with `min_wrapping_ttl` and `max_wrapping_ttl`.

## Before you start

You need a terminal, `jq`, and basic KV skills. Your playground is a single-node `kind` cluster with **OpenBao v2.7.1** in the namespace `openbao`, already initialized and unsealed, with the `bao` command-line tool on your PATH. The lab-only root token is in the Kubernetes Secret `openbao-init`.

Each part starts with the same short set-up: a port-forward in a second terminal and two environment variables, so `bao` knows the address and the token.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
