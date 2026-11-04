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

## Step 2: Enable the engine and create the CA key

```sh
bao secrets enable ssh
bao write ssh/config/ca generate_signing_key=true
bao read -field=public_key ssh/config/ca
```

The last command prints the public key that a server would trust.

## Step 3: Write the role

```sh
bao write ssh/roles/deploy -<<'JSON'
{
  "key_type": "ca",
  "allow_user_certificates": true,
  "allowed_users": "deploy,ops",
  "default_user": "deploy",
  "default_extensions": {"permit-pty": ""},
  "ttl": "30m",
  "max_ttl": "4h"
}
JSON
bao read ssh/roles/deploy
```

## Step 4: Sign the client key

```sh
kubectl -n clients get configmap ssh-client-key -o jsonpath='{.data.public_key}' > client.pub
bao write -field=signed_key ssh/sign/deploy public_key=@client.pub valid_principals=deploy > client-cert.pub
ssh-keygen -L -f client-cert.pub
bao write ssh/sign/deploy public_key=@client.pub valid_principals=root
```

The certificate lists the principal `deploy`, the extension `permit-pty` and a validity of 30 minutes. The last command is refused because `root` is not an allowed principal. If `ssh-keygen` is not installed, skip the inspection; the grader does not need it.

## Step 5: Submit

Run `astrona submit` after each step to see which check passes.

## Why this works

The role is the only place that decides what the CA signs. With `allowed_users` set to two exact names, a caller cannot obtain a certificate for `root`, and the TTL settings bound how long a certificate is valid.
