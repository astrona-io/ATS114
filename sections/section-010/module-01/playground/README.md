# Store And Version Secrets With KV Version 2 — Playground

- **Slug:** ats-114-playground-010-01
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading

A sandbox with OpenBao v2.7.1 initialized and unsealed. Nothing to submit.

## Run it

```sh
astrona run -c .
astrona destroy ats-114-playground-010-01
```

`astrona destroy` takes the environment name (`metadata.name`), not the config path.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition |
| `bootstrap/prepare.sh` | Installs Helm, `bao` and OpenBao, adds the CoreDNS rewrite, initializes and unseals OpenBao |
| `manifests/` | Helm values, the tester pod |
| `docs/overview.md` | What the environment contains and ideas to try |
