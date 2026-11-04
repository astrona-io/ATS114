# Solution: Move And Tune Secrets Engine Mounts

Work the task yourself first. Running `astrona submit -c sections/section-010/module-02/labs/lab-01` after a step tells you which checks pass.

The grader checks three things: the mount was moved and its secret is intact, the mount has the new settings, and the unused mount is gone.

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

## Step 2: Look at the mount table

```sh
bao secrets list -detailed
bao kv get -mount=scratch report/q1
```

You see `scratch/` and `old-reports/`, both of type `kv` with version 2, and the secret with `owner` `finance`.

## Step 3: Move the mount

```sh
bao secrets move scratch/ apps/
bao secrets list
bao kv get -mount=apps report/q1
```

The mount `scratch/` is gone, `apps/` is listed, and the secret has the same fields. The move runs in the background, so if the read fails at once, run it again after a few seconds.

## Step 4: Tune the new mount

```sh
bao secrets tune -default-lease-ttl=1h -max-lease-ttl=24h -description="Application secrets" apps
bao read sys/mounts/apps/tune
```

The response shows `default_lease_ttl` `3600`, `max_lease_ttl` `86400` and the new description.

## Step 5: Disable the unused mount

```sh
bao secrets disable old-reports/
bao secrets list
```

## Step 6: Submit

```sh
astrona submit -c sections/section-010/module-02/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Enable `apps/`, copy the secret, disable `scratch/` | Works for the data, but the version history and the accessor of the mount are lost |
| Disable `scratch/` and enable `apps/` | The secret `report/q1` is deleted for good |
| Tune `scratch/` before the move | The settings move with the mount, but the grader needs them checked on `apps/` after the move |
| Disable `old-reports/` by mistake as `old-reports` with a typo | The command fails and the mount stays |
