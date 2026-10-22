# Solution: Rotate Everything After A Leak

Work the task yourself first. Running `astrona submit -c sections/section-040/capstone/labs/lab-01` after a step tells you which checks pass.

The grader checks six things: the KV leak, the stored records (new version and original text), the retired key version, the four leaked leases and their users, and the rotated connection password with a working new credential.

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

## Step 2: Remove the KV leak

```sh
bao kv metadata get -mount=secret inventory/db
bao kv destroy -mount=secret -versions=2 inventory/db
bao kv rollback -mount=secret -version=1 inventory/db
bao kv get -mount=secret inventory/db
```

Version 2 is destroyed, and the current version (3) holds the data of version 1 without `debug_dump`.

## Step 3: Rotate the Transit key, rewrap and retire

The key has only version 1, and both records use it. Rotate first, so there is a new version to move to:

```sh
bao write -f transit/keys/inventory-records/rotate
for record in record-a record-b; do
  CIPHERTEXT=$(kubectl -n clients get configmap encrypted-records -o jsonpath="{.data.$record}")
  NEW=$(bao write -field=ciphertext transit/rewrap/inventory-records ciphertext="$CIPHERTEXT")
  kubectl -n clients patch configmap encrypted-records --type merge -p "{\"data\":{\"$record\":\"$NEW\"}}"
done
bao write transit/keys/inventory-records/config min_decryption_version=2
bao read transit/keys/inventory-records
```

Both records now start with `vault:v2:`, and `min_decryption_version` equals `latest_version`, `2`.

## Step 4: Revoke the leaked credentials and rotate the connection password

```sh
bao lease revoke -prefix -sync database/creds/inventory-readonly
bao write -force database/rotate-root/inventory-db
bao read database/creds/inventory-readonly
```

The prefix revokes all four leases and OpenBao drops their users. After the rotation, only OpenBao knows the password of `openbao_admin`, and it still creates credentials.

## Step 5: Submit

```sh
astrona submit -c sections/section-040/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| `bao kv delete` instead of `destroy` | The leaked version can be undeleted |
| Raise `min_decryption_version` without rotating | There is no newer version to move to, so the leaked version stays the only one that encrypts |
| Re-create the Transit key | Neither record decrypts any more |
| Only revoke the leases | The leaked `openbao_admin` password still opens the database |
