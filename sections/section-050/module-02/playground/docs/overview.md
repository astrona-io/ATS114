# Overview: SSH Certificates And One-Time Passwords With The SSH Engine (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs OpenBao and initializes and unseals it, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **OpenBao v2.7.1** in the namespace `openbao`, one pod `openbao-0`, initialized with one lab-only unseal key and already unsealed. The SSH engine is not enabled.
- The lab-only root token and unseal key in the Kubernetes Secret `openbao-init`. A real installation never keeps them there.
- The **`bao`** command-line tool v2.7.1 on your PATH, and a `tester` pod in the namespace `clients`.

## Connect your terminal

Start the port-forward in a second terminal and leave it running:

```sh
kubectl -n openbao port-forward svc/openbao 8200:8200
```

Then, in each terminal where you run `bao`:

```sh
export BAO_ADDR=http://openbao.localtest.me:8200
export BAO_TOKEN=$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)
```

## Helpers

`ssh_new NAME` creates a key pair named NAME in the current directory. `ssh_sign ROLE NAME PRINCIPAL` signs NAME.pub through a role and saves NAME-cert.pub.

```sh
ssh_new() { ssh-keygen -q -t ed25519 -N "" -C "$1" -f "./$1"; }
ssh_sign() { bao write -field=signed_key ssh/sign/"$1" public_key=@"$2".pub valid_principals="$3" > "$2"-cert.pub; }
```

Enable the engine first with `bao secrets enable ssh`, and create the CA with `bao write ssh/config/ca generate_signing_key=true`.

## Practice tasks

- Create a CA role, sign a key with `ssh_sign`, and read the result with `ssh-keygen -L -f NAME-cert.pub`.
- Ask for a principal that is not in `allowed_users` and read the error.
- Change `ttl`, sign again, and compare the `Valid` lines.
- Add `default_critical_options` with `source-address` and read it in the certificate.
- Request an extension that is not in `allowed_extensions`.
- Create an OTP role with `cidr_list`, request a password for an address inside and outside the range.
- Call `ssh/verify` twice with the same password.
- Mount a second engine at `ssh-prod` and generate a different CA key.
