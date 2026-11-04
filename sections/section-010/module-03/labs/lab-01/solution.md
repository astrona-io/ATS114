# Solution: Hand Over A Secret With Response Wrapping

Work the task yourself first. Running `astrona submit -c sections/section-010/module-03/labs/lab-01` after a step tells you which checks pass.

The grader checks three things: the token in `delivery` is a valid wrapping token for the right secret and lifetime, the partner key is stored, and the partner token was used.

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

## Step 2: Wrap the secret for the new instance

The wrap TTL is 10 minutes. The field flag prints only the wrapping token, so nothing from the secret reaches your terminal:

```sh
DELIVERY_TOKEN=$(bao read -wrap-ttl=10m -field=wrapping_token secret/data/inventory/api)
kubectl -n clients create configmap delivery --from-literal=token="$DELIVERY_TOKEN"
```

Look the token up without using it:

```sh
bao write -format=json sys/wrapping/lookup token="$DELIVERY_TOKEN" | jq '.data'
```

The creation path is `secret/data/inventory/api` and the creation TTL is `600`.

## Step 3: Unwrap the partner token

```sh
RECEIVED_TOKEN=$(kubectl -n clients get configmap received -o jsonpath='{.data.token}')
PARTNER_KEY=$(bao unwrap -format=json "$RECEIVED_TOKEN" | jq -r '.data.data["api-key"]')
bao kv put -mount=secret inventory/partner api-key="$PARTNER_KEY"
```

You can unwrap only once. If the unwrap fails because you tried it before, ask the lab for a fresh start with `astrona destroy` and `astrona run`.

## Step 4: Submit

```sh
astrona submit -c sections/section-010/module-03/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Unwrap the `delivery` token to check it | The token is used up and the new instance gets an error |
| Wrap with the default TTL | No wrapping happens, or the TTL is not 600 seconds |
| Look for the partner key in KV | It is not stored anywhere else; only the wrapping token holds it |
| Run `bao unwrap` twice | The second call fails; copy the key the first time |
