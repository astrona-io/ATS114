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

## Step 2: Enable the engine and create the generated key

```sh
bao secrets enable totp
bao write totp/keys/deploy-approval generate=true exported=false \
    issuer=Inventory account_name=release-manager \
    algorithm=SHA256 digits=8 period=60
bao read totp/keys/deploy-approval
```

The read shows `SHA256`, `8` and `60`. `exported=false` means that no URL or QR code is returned.

## Step 3: Import the partner secret

```sh
SECRET=$(kubectl -n clients get configmap partner-totp-secret -o jsonpath='{.data.secret}')
bao write totp/keys/partner-vpn key="$SECRET" \
    issuer=Partner account_name=ops@partner.example
bao read totp/code/partner-vpn
```

The code is the same as the one an authenticator app shows for that secret.

## Step 4: Write the validator policy

```sh
printf 'path "totp/code/deploy-approval" {\n  capabilities = ["update"]\n}\n' | bao policy write totp-validator -
```

Test it:

```sh
VALIDATOR=$(bao token create -policy=totp-validator -ttl=10m -field=token)
CODE=$(bao read -field=code totp/code/deploy-approval)
BAO_TOKEN="$VALIDATOR" bao write totp/code/deploy-approval code="$CODE"
BAO_TOKEN="$VALIDATOR" bao read totp/code/deploy-approval
```

The write reports `valid` as `true`, and the read fails with `permission denied`.

## Step 5: Submit

Run `astrona submit` after each step to see which check passes.

## Why this works

A key stores its settings when it is created, and the code is computed from the secret and the time, so two keys with the same secret and settings give the same code. Validating is a write and generating is a read on the same path, so a policy with only `update` lets a service check codes without being able to create them.
