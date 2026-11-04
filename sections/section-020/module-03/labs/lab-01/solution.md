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

## Step 2: Revoke the leaked certificate

```sh
SERIAL=$(kubectl -n openbao get configmap compromised-cert -o jsonpath='{.data.serial}')
bao write pki/revoke serial_number="$SERIAL"
```

The response contains a `revocation_time`. Check it:

```sh
bao read -field=revocation_time pki/cert/"$(printf '%s' "$SERIAL" | tr ':' '-')"
```

## Step 3: Configure the CRL

`pki/config/crl` replaces unspecified fields with defaults, so read it first and send every field you want to keep. Here, only the three fields below differ from the defaults, and the OCSP responder stays enabled:

```sh
bao write pki/config/crl expiry=24h auto_rebuild=true auto_rebuild_grace_period=6h
bao read pki/config/crl
```

## Step 4: Set the URLs

```sh
bao write pki/config/urls \
    issuing_certificates="http://openbao.localtest.me:8200/v1/pki/ca" \
    crl_distribution_points="http://openbao.localtest.me:8200/v1/pki/crl" \
    ocsp_servers="http://openbao.localtest.me:8200/v1/pki/ocsp"
```

## Step 5: Turn on auto-tidy

```sh
bao write pki/config/auto-tidy enabled=true interval_duration=12h \
    tidy_cert_store=true tidy_revoked_certs=true safety_buffer=72h
bao read pki/config/auto-tidy
```

## Step 6: Submit

Run `astrona submit` after each step to see which check passes.

## Why this works

The revocation marks the stored certificate and rebuilds the CRL. The CRL configuration controls the validity and the timer rebuild. The URLs are written into certificates issued from now on, and auto-tidy removes expired entries on a schedule with a buffer so that clients can still see recent revocations.
