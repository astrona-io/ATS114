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

## Step 2: Create the key

```sh
bao write -f transit/keys/release-signing type=ed25519
```

## Step 3: Sign the manifest and publish the signature

Take the manifest exactly as stored and Base64-encode it without line breaks:

```sh
INPUT=$(kubectl -n clients get configmap release-manifest -o jsonpath='{.data.manifest\.json}' | base64 | tr -d '\n')
SIGNATURE=$(bao write -field=signature transit/sign/release-signing input="$INPUT")
kubectl -n clients create configmap release-signature --from-literal=signature="$SIGNATURE"
```

Check it:

```sh
bao write transit/verify/release-signing input="$INPUT" signature="$SIGNATURE"
```

`valid` is `true`.

## Step 4: Create the verifier policy

```sh
printf 'path "transit/verify/release-signing" {\n  capabilities = ["update"]\n}\n' | bao policy write release-verifier -
```

Test it with a token:

```sh
VERIFIER=$(bao token create -policy=release-verifier -ttl=10m -field=token)
BAO_TOKEN="$VERIFIER" bao write transit/verify/release-signing input="$INPUT" signature="$SIGNATURE"
BAO_TOKEN="$VERIFIER" bao write transit/sign/release-signing input="$INPUT"
```

The verify works and the sign fails with `permission denied`.

## Step 5: Submit

Run `astrona submit` after each step to see which check passes.

## Why this works

The key never leaves OpenBao, and the signature is bound to the exact bytes of the manifest. Transit endpoints take a write, so the policy gives `update` on the verify path only. Signing, reading the key and every other path are denied by default.
