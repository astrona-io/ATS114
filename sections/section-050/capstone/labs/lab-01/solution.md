# Solution

## Step 1: Connect

Start the port-forward in a second terminal and leave it running:

```sh
kubectl -n openbao port-forward svc/openbao 8200:8200
```

In the first terminal:

```sh
export BAO_ADDR=http://openbao.localtest.me:8200
export BAO_TOKEN=$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)
```

## Step 2: Restrict the role

```sh
bao read ssh/roles/ops
bao write ssh/roles/ops -<<'JSON'
{
  "key_type": "ca",
  "allow_user_certificates": true,
  "allowed_users": "ops",
  "default_user": "ops",
  "default_extensions": {"permit-pty": ""},
  "default_critical_options": {"source-address": "10.0.0.0/8"},
  "ttl": "15m",
  "max_ttl": "1h"
}
JSON
bao read ssh/roles/ops
```

Send the whole role in one write, so that no old value such as the wide principal list stays in place. Read the role again to confirm.

## Step 3: Replace the TOTP key

```sh
bao delete totp/keys/prod-approval
bao write totp/keys/prod-approval generate=true exported=false \
    issuer=Inventory account_name=prod algorithm=SHA256 digits=8 period=30
bao read totp/keys/prod-approval
```

A generated key has a new secret that nobody else knows, so the leaked secret no longer produces the codes.

## Step 4: Write the signer policy

```sh
printf 'path "ssh/sign/ops" {\n  capabilities = ["update"]\n}\n' | bao policy write ssh-signer -
```

Test it:

```sh
kubectl -n clients get configmap ssh-client-key -o jsonpath='{.data.public_key}' > client.pub
SIGNER=$(bao token create -policy=ssh-signer -ttl=10m -field=token)
BAO_TOKEN="$SIGNER" bao write -field=signed_key ssh/sign/ops public_key=@client.pub valid_principals=ops
BAO_TOKEN="$SIGNER" bao read ssh/config/ca
```

The sign succeeds, and the read fails with `permission denied`.

## Step 5: Submit

Run `astrona submit` after each step to see which check passes.

## Why this works

Signing is a write on `ssh/sign/<role>`, so a policy with `update` on one path gives a caller exactly one role. The role holds the limits, so tightening the role limits every caller at once. A TOTP secret that has been seen cannot be made secret again, so the key has to be replaced.
