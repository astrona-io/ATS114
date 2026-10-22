# Welcome To The Course

This course trains you for the **Secrets Engines & Dynamic Credential Lifecycle** part of the Astrona **OpenBao** training path. That part is 25% of the path. This page tells you who the course is for, what you can do at the end, which words and example setup it uses, and how its pages fit together.

## Who this course is for

You know your way around Kubernetes: namespaces, pods, Secrets, ConfigMaps, `kubectl get`, `kubectl exec` and `kubectl port-forward`. You know what a TLS certificate is and you can write a simple SQL query. You have seen OpenBao before: you know that it must be unsealed and that every request needs a token. Each new idea in this course is explained the first time it appears.

## What you can do at the end

OpenBao is a server you send requests to, so this course does not ask you to remember words. It asks you to create secrets, certificates and database users, prove that they work, and clean them up when something leaks. The course has four topics, and each one turns into a set of skills you will practise.

The first topic is **static secrets in KV version 2**, the key/value engine that keeps every version of a secret. You will learn to:

- Write, read and patch secrets, and read older versions.
- Tell a soft delete from a destroy, undelete a version, and roll back a bad write.
- Limit the number of versions and require check-and-set on a secret.

The second topic is **certificates with the PKI engine**, which turns OpenBao into a certificate authority. You will learn to:

- Build a root CA and an intermediate CA signed by it.
- Write a role that limits names and lifetimes, and issue certificates from it.
- Check a certificate chain with `openssl` and set the URLs a certificate carries.

The third topic is **dynamic database credentials**: database users that OpenBao creates on request and removes again. You will learn to:

- Connect the database secrets engine to PostgreSQL.
- Write a role that creates read-only users with a short lease.
- Renew and revoke leases, revoke many at once, and rotate OpenBao's own database password.

The fourth topic is **encryption as a service with the Transit engine**. You will learn to:

- Encrypt and decrypt data with a key that never leaves OpenBao.
- Rotate a key, rewrap stored data, and retire old key versions.

Everything is written for **OpenBao v2.7.1**.

## The words this course uses

The pages use OpenBao's, PostgreSQL's and Kubernetes' own terms, because those are the words you meet in the product, the logs and the documentation. Each term gets a short, plain definition the first time it appears on a page. A few terms come back on almost every page, so here they are up front.

A **secrets engine** is a component that OpenBao enables at a path, called a **mount**. It stores, creates or encrypts data. A **static secret** is a value that someone stored and OpenBao only returns. A **dynamic secret** is a value OpenBao creates when you ask for it, such as a database user. Every dynamic secret has a **lease**: the time it is valid, with an ID you use to renew or revoke it.

Four engines come back on almost every page:

| Engine | What it does |
| --- | --- |
| `kv-v2` | Stores key/value secrets and keeps a numbered version of every write |
| `pki` | Acts as a certificate authority: it signs and issues X.509 certificates |
| `database` | Creates database users on request and removes them when their lease ends |
| `transit` | Encrypts and decrypts data with keys that never leave OpenBao |

## The example setup in your playground

Every playground and lab runs the same small setup. OpenBao runs in the namespace `openbao` as one pod, `openbao-0`. It is already initialized and unsealed, so you can start working at once. A `tester` pod in the namespace `clients` has `curl`, `jq` and `openssl`, and the graders use it to check your work. In the database section, a PostgreSQL pod in the namespace `data` holds the database `inventory` with a small table `items`.

Inside OpenBao the pages use the same names everywhere: secrets under `inventory/` in the mount `secret/`, the certificate authorities "Inventory Root CA" and "Inventory Intermediate CA", the database role `inventory-readonly`, and the Transit key `inventory-records`. Many labs start with something broken on purpose. That is the material, not a fault in the course.

## How the course is laid out

The course has four sections. It starts with the engine that only stores what you give it, and moves on to engines that create and protect data for you.

| Section | What it covers |
| --- | --- |
| 010 | Static Secrets With KV Version 2 |
| 020 | Certificates With The PKI Engine |
| 030 | Dynamic Database Credentials |
| 040 | Encryption As A Service With Transit |

Each section has one or more **modules**, and each module teaches one skill. A module brings together four kinds of material:

| What | What it is for | Graded? |
| --- | --- | --- |
| **Reading** | A short landing page, a few chapters that teach one idea each, and a summary | No |
| **Playground** | A small cluster on your own machine, to try everything you read | No |
| **Lab** | A cluster in a starting state, a task, and a grader that checks your work | Yes |
| **Capstone** | The last lab in a section, with several faults at once | Yes |

The best order is simple: read the chapters with the playground open next to them, take each lab when a chapter sends you to it, and finish each section with its capstone. The next part of this page explains how a module's pages guide you through that order.

## How to read a page

A module starts with a **landing page**. It says what the module teaches, what you should know first, and the order of its chapters. At the bottom of the landing page you start the module's playground, and you keep it running while you read.

The chapters (the parts of a module) read like the chapters of a technical book. Each one opens with the problem it solves, explains one idea in connected paragraphs, and closes with what you now know. The hands-on steps sit right in the text: a sentence or two on what to run and why, the command, and then what the result shows. Run each step in your playground as you reach it. You learn more from one real result than from a page of text.

Every chapter ends with a box of common pitfalls, the mistakes people make most often with what the chapter taught, and how to spot them. Now and then a page also has a tip box with a habit or shortcut you can use again, well beyond that page. The two boxes look like this:

> [!TIP]
> **A tip.** A habit or shortcut you can use again, well beyond this one page.

> [!WARNING]
> **Common pitfalls.** The mistakes people make most often with what you just learned, and how to spot them. Every chapter ends with one.

When a graded lab tests what a chapter taught, that chapter ends with a **Your mission** section. It tells you what the lab asks, then gives every command you need, in order: pause the playground with `astrona stop`, start the lab with `astrona run`, and send your work for grading with `astrona submit`. Solve the lab on your own before you look at its solution. When the lab is done, remove it with `astrona destroy` and start the playground again with `astrona start`, so you can carry on reading where you left off.

The last page of every module is the **Summary**. It sums up what you learned in a few short paragraphs, organised by idea. It also ends the module's hands-on work: the Summary page removes the playground, so your machine is clean before the next module.

One rule holds on every page. Code blocks are exactly what you type. Never change a command to make it "look right". If the result is different from what the page describes, that difference is the lesson.
