# Solution: Rotate The Root Issuer Of A PKI Mount

Work the task yourself first. Running `astrona submit -c sections/section-020/module-02/labs/lab-01` after a step tells you which checks pass.

The grader checks two things: the new root is the default and signs new certificates, and the old root is retired but not deleted.

## Step 1: Connect your terminal

Start the port-forward in a second terminal and leave it running:

```sh
kubectl -n openbao port-forward svc/openbao 8200:8200
```

Then:

```sh
export BAO_ADDR=http://openbao.localtest.me:8200
export BAO_TOKEN=$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)
```

## Step 2: Look at the issuers

```sh
bao list pki/issuers
bao read pki/config/issuers
bao read -field=usage pki/issuer/inventory-root-1
```

One issuer exists and it is the default. Its usage contains `issuing-certificates`.

## Step 3: Add the new root

```sh
bao write pki/root/rotate/internal \
    common_name="Inventory Root CA 2" \
    issuer_name=inventory-root-2 \
    key_name=inventory-root-2-key \
    ttl=87600h
bao list pki/issuers
```

Two issuers exist. The default is still the first one.

## Step 4: Make the new root the default

```sh
bao write pki/config/issuers default=inventory-root-2
bao write -format=json pki/issue/inventory-svc common_name=api.inventory.svc \
    | jq -r '.data.issuing_ca' | openssl x509 -noout -subject
```

The issuing CA is `CN=Inventory Root CA 2`.

## Step 5: Retire the old root

```sh
bao write pki/issuer/inventory-root-1 usage=crl-signing,ocsp-signing
bao read -field=usage pki/issuer/inventory-root-1
```

The usage no longer contains `issuing-certificates`.

## Step 6: Submit

```sh
astrona submit -c sections/section-020/module-02/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Delete `inventory-root-1` | Certificates it signed can no longer be verified or revoked through the mount |
| Generate the new root with `root/generate` and no name | It works, but the grader looks for an issuer named `inventory-root-2` |
| Pin the role to `inventory-root-2` with `issuer_ref` | The task says not to change the role; the default does the job |
| Skip the usage change | The old root can still sign new certificates if a role is pinned to it |
