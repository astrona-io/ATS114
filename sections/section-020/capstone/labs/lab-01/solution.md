# Solution: Repair A Broken Certificate Chain

Work the task yourself first. Running `astrona submit -c sections/section-020/capstone/labs/lab-01` after a step tells you which checks pass.

The grader checks five things: the root CA is unchanged, the intermediate is signed by it, the role, a certificate that verifies (and a refused name), and the CRL URL inside a new certificate.

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

## Step 2: Find out why issuing fails

```sh
bao write pki_int/issue/inventory-svc common_name=api.inventory.svc ttl=1h
curl -s $BAO_ADDR/v1/pki_int/ca/pem
bao read pki_int/roles/inventory-svc
bao list pki/roles
```

The issue request fails, and `pki_int/ca/pem` returns no certificate: the intermediate has a key from an earlier `generate/internal`, but its CSR was never signed and installed. The role allows `inventory.local` without subdomains and up to 720 hours. `bao list pki/roles` shows a role `inventory-svc` on the root mount.

## Step 3: Sign and install the intermediate

The old CSR is lost, so generate a new one, sign it with the existing root and install the result. The root stays as it is:

```sh
curl -s $BAO_ADDR/v1/pki/ca/pem > root-ca.pem
bao write -field=csr pki_int/intermediate/generate/internal \
    common_name="Inventory Intermediate CA" ttl=43800h > pki_int.csr
bao write -field=certificate pki/root/sign-intermediate \
    csr=@pki_int.csr format=pem_bundle ttl=43800h > intermediate.cert.pem
bao write pki_int/intermediate/set-signed certificate=@intermediate.cert.pem
curl -s $BAO_ADDR/v1/pki_int/ca/pem > intermediate-ca.pem
openssl verify -CAfile root-ca.pem intermediate-ca.pem
```

`openssl verify` ends with `OK`.

## Step 4: Fix the role and remove the role on the root mount

```sh
bao write pki_int/roles/inventory-svc \
    allowed_domains=inventory.svc allow_subdomains=true max_ttl=72h
bao delete pki/roles/inventory-svc
```

## Step 5: Set the URLs on pki_int

```sh
bao write pki_int/config/urls \
    issuing_certificates="http://openbao.localtest.me:8200/v1/pki_int/ca" \
    crl_distribution_points="http://openbao.localtest.me:8200/v1/pki_int/crl"
```

## Step 6: Prove it

```sh
bao write -field=certificate pki_int/issue/inventory-svc common_name=web.inventory.svc ttl=1h > web.pem
openssl verify -CAfile root-ca.pem -untrusted intermediate-ca.pem web.pem
openssl x509 -in web.pem -noout -text | grep -A2 'CRL Distribution'
bao write pki_int/issue/inventory-svc common_name=www.example.com
```

The certificate verifies, names the CRL URL, and `www.example.com` is refused.

## Step 7: Submit

```sh
astrona submit -c sections/section-020/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Generate a new root CA | Every client that trusts the old root stops trusting your certificates; the grader compares the root fingerprint |
| Issue from the role on `pki/` | Works, but the root key signs service certificates; the grader requires that role to be gone |
| Set `config/urls` on `pki/` only | Certificates from `pki_int/` still carry no CRL URL |
