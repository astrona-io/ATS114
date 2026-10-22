# ATS114 — Secrets Engines & Dynamic Credential Lifecycle (OpenBao)

Course material for the **Secrets Engines & Dynamic Credential Lifecycle**
domain of the Astrona OpenBao training path
([ATP022](https://github.com/astrona-io/ATP022)), which is **25% of the path**.
Written for **OpenBao v2.7.1**.

> **Status: draft, not yet run.** Every page, playground and lab was written
> from the OpenBao 2.7 documentation and the v2.7.1 source. None has been
> started on a cluster, and no lab has passed `astrona test` yet. See
> `CLAUDE.md` for the facts to check first.

The course opens with an Introduction in `sections/intro/` (welcome, machine
setup, how the course is made). Everything else lives under `sections/`. Each
section contains:

- **A module** — a reading chapter split into a short landing page, ordered
  deep-dive parts and a summary page, a throwaway **playground** to explore in,
  and a graded **lab** placed right after the part it tests.
- **A capstone** — one larger graded lab with several independent faults.

---

## Sections

| Section | Title | Modules | Labs | Topic |
| --- | --- | --- | --- | --- |
| [010](sections/section-010) | Static Secrets With KV Version 2 | 1 | 1 + capstone | KV v2 |
| [020](sections/section-020) | Certificates With The PKI Engine | 1 | 1 + capstone | PKI |
| [030](sections/section-030) | Dynamic Database Credentials | 1 | 1 + capstone | Database engine and leases |
| [040](sections/section-040) | Encryption As A Service With Transit | 1 | 1 + capstone | Transit |

The order goes from the simplest engine to the ones that create and protect
data. KV version 2 only stores what you write. PKI creates certificates on
request. The database engine creates users that expire, which is where leases
matter most. Transit stores nothing at all and only encrypts.

---

## Modules

| Module | Reader | Parts | Labs |
| --- | --- | --- | --- |
| 010-01 | [Store And Version Secrets With KV Version 2](sections/section-010/module-01/course.md) | 3 | [lab-01](sections/section-010/module-01/labs/lab-01) |
| 020-01 | [Run An Internal Certificate Authority With The PKI Engine](sections/section-020/module-01/course.md) | 3 | [lab-01](sections/section-020/module-01/labs/lab-01) |
| 030-01 | [Generate Short-Lived Database Credentials](sections/section-030/module-01/course.md) | 3 | [lab-01](sections/section-030/module-01/labs/lab-01) |
| 040-01 | [Encrypt Data With The Transit Engine](sections/section-040/module-01/course.md) | 2 | [lab-01](sections/section-040/module-01/labs/lab-01) |

---

## Capstones

| Capstone | Scenario | Faults |
| --- | --- | --- |
| [010](sections/section-010/capstone/labs/lab-01) | Clean Up A KV Mount Before An Audit | a leaked field in the current version, no check-and-set, no mount-wide version limit |
| [020](sections/section-020/capstone/labs/lab-01) | Repair A Broken Certificate Chain | an intermediate CA never signed, a role with the wrong domain, a role on the root mount, no URLs |
| [030](sections/section-030/capstone/labs/lab-01) | Clean Up After A Database Credential Leak | month-long leases, four leaked credentials, a connection password nobody rotated |
| [040](sections/section-040/capstone/labs/lab-01) | Rotate Everything After A Leak | a leaked KV version, records on a key version to retire, leaked database credentials |

---

## The lab environment

Every playground and lab is a **kind** cluster with OpenBao v2.7.1 installed by
the `openbao` Helm chart 0.30.4, **initialized and unsealed** with one lab-only
key. The lab-only root token and unseal key are in the Secret `openbao-init`
in the namespace `openbao`. Section 030 and the last capstone add PostgreSQL 17
in the namespace `data`.

OpenBao answers at `http://openbao.localtest.me:8200` everywhere: on the
reader's machine through `kubectl -n openbao port-forward svc/openbao 8200:8200`,
and inside the cluster through a CoreDNS rewrite added by the bootstrap. The
listener has no TLS (lab-only).

## Running a playground

```bash
astrona run --git ssh://git@github.com/astrona-io/ATS114.git -c sections/<section>/<module>/playground
astrona destroy <name>
```

## Running a lab

```bash
astrona run --git ssh://git@github.com/astrona-io/ATS114.git -c sections/<section>/<module>/labs/lab-01
astrona submit -c sections/<section>/<module>/labs/lab-01
astrona destroy <name>
```

Each lab grades the **final state** of OpenBao (and PostgreSQL) with
independent checks, and several of them reject the plausible-but-wrong fix:
writing a secret again instead of recovering it, issuing service certificates
from the root CA, giving OpenBao the PostgreSQL superuser, or creating a new
Transit key instead of rotating the old one.
