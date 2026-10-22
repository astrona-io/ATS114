# Solution: Rewrap Records And Retire Old Key Versions

Work the task yourself first. Running `astrona submit -c sections/section-040/module-01/labs/lab-01` after a step tells you which checks pass.

The grader checks three things: every stored record uses the newest version, every record decrypts to its original text, and only the newest version can decrypt.

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

## Step 2: Read the key and the stored records

```sh
bao read transit/keys/inventory-records
kubectl -n clients get configmap encrypted-records -o yaml
```

The key shows `latest_version` `3` and `min_decryption_version` `1`. The records start with `vault:v1:`, `vault:v1:` and `vault:v2:`: none uses the newest version.

## Step 3: Rewrap every record and save it

Rewrap returns the new ciphertext without the plaintext. Saving it back into the ConfigMap is your job, because Transit stores nothing:

```sh
for record in record-a record-b record-c; do
  CIPHERTEXT=$(kubectl -n clients get configmap encrypted-records -o jsonpath="{.data.$record}")
  NEW=$(bao write -field=ciphertext transit/rewrap/inventory-records ciphertext="$CIPHERTEXT")
  kubectl -n clients patch configmap encrypted-records --type merge -p "{\"data\":{\"$record\":\"$NEW\"}}"
done
kubectl -n clients get configmap encrypted-records -o yaml
```

Every record now starts with `vault:v3:`. Check one before you retire anything:

```sh
bao write -field=plaintext transit/decrypt/inventory-records \
    ciphertext="$(kubectl -n clients get configmap encrypted-records -o jsonpath='{.data.record-a}')" | base64 -d
```

## Step 4: Retire the old versions

```sh
bao write transit/keys/inventory-records/config min_decryption_version=3
bao read transit/keys/inventory-records
```

`min_decryption_version` is now `3`, equal to `latest_version`.

## Step 5: Submit

```sh
astrona submit -c sections/section-040/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Raise `min_decryption_version` first | `record-a`, `record-b` and `record-c` stop decrypting before you can rewrap them |
| Rewrap but do not patch the ConfigMap | The stored records are still on the old versions |
| Delete the key and create it again | New key material: no stored record decrypts any more |
| Rotate again before rewrapping | Works, but the records must then reach the new newest version |
