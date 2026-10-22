# Solution: Build A Two-Tier CA For The Inventory Services

Work the task yourself first. Running `astrona submit -c sections/section-020/module-01/labs/lab-01` after a step tells you which checks pass.

The grader checks five things: the root CA, the intermediate CA and its signature, the role, a certificate that verifies against the chain (and a refused name), and the URLs of `pki_int/`.

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

## Step 2: Build the root CA

Raise the maximum lease time first, or the 10-year certificate is capped at 32 days. `internal` keeps the private key inside OpenBao.

```sh
bao secrets enable pki
bao secrets tune -max-lease-ttl=87600h pki
bao write -field=certificate pki/root/generate/internal \
    common_name="Inventory Root CA" ttl=87600h > root-ca.pem
bao write pki/config/urls \
    issuing_certificates="http://openbao.localtest.me:8200/v1/pki/ca" \
    crl_distribution_points="http://openbao.localtest.me:8200/v1/pki/crl"
```

The URLs on the root mount are optional for the grader, but they put the right addresses into the intermediate certificate.

## Step 3: Build and sign the intermediate CA

```sh
bao secrets enable -path=pki_int pki
bao secrets tune -max-lease-ttl=43800h pki_int
bao write -field=csr pki_int/intermediate/generate/internal \
    common_name="Inventory Intermediate CA" ttl=43800h > pki_int.csr
bao write -field=certificate pki/root/sign-intermediate \
    csr=@pki_int.csr format=pem_bundle ttl=43800h > intermediate.cert.pem
bao write pki_int/intermediate/set-signed certificate=@intermediate.cert.pem
```

Check the signature:

```sh
curl -s $BAO_ADDR/v1/pki_int/ca/pem > intermediate-ca.pem
openssl verify -CAfile root-ca.pem intermediate-ca.pem
```

`openssl verify` ends with `OK`.

## Step 4: Set the URLs and write the role on pki_int

```sh
bao write pki_int/config/urls \
    issuing_certificates="http://openbao.localtest.me:8200/v1/pki_int/ca" \
    crl_distribution_points="http://openbao.localtest.me:8200/v1/pki_int/crl"
bao write pki_int/roles/inventory-svc \
    allowed_domains=inventory.svc allow_subdomains=true max_ttl=72h
```

## Step 5: Prove it

```sh
bao write -field=certificate pki_int/issue/inventory-svc common_name=api.inventory.svc ttl=1h > api.pem
openssl verify -CAfile root-ca.pem -untrusted intermediate-ca.pem api.pem
bao write pki_int/issue/inventory-svc common_name=www.example.com
```

The first certificate verifies with `OK`; the request for `www.example.com` is refused because the role does not allow that name.

## Step 6: Submit

```sh
astrona submit -c sections/section-020/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| One mount with only a root CA and a role on it | The root key signs every service certificate; the grader checks for an intermediate and refuses a role on `pki/` |
| `generate/exported` | The CA key leaves OpenBao in the response, which the task forbids |
| Skipping `tune` | The root and intermediate expire after 32 days |
| `allowed_domains=inventory.svc` without `allow_subdomains` | `api.inventory.svc` is refused |
