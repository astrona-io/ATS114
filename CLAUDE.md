# Writing style for this repo

All study text here (course pages, lab docs, READMEs, comments in YAML and
scripts) is for people learning a technical subject, often for a
certification exam. Many of them are not native English speakers and have no
university degree.

## Technical documentation in plain English

This is technical documentation. Say exactly what the system does, with the
real technical terms, in clear and simple English. Never hide a concept
behind a metaphor, a made-up name or a vague word: the reader must learn the
words they will meet in the product, the logs and the exam.

Strict guidelines:

1. Use the correct technical term every time (request, response, pod,
   namespace, Service, sidecar proxy, certificate, mTLS, JWT, listener). The
   first time a term appears in a file, define it in one plain sentence that
   says what it is and what it does. Spell out every acronym on first use.
2. No metaphors or analogies in explanations. Not "the communications
   officer", but "the sidecar proxy (Envoy)"; not "a signal", but "a
   request"; not "the planet", but "the namespace".
3. Simple sentences. Target a Flesch-Kincaid Grade Level of 8 or 9 for the
   prose around the terms. Keep sentences direct; split long sentences into
   two. No corporate buzzwords.
4. Use short paragraphs (max 3-4 sentences per paragraph).
5. Use the active voice ("istiod sends the configuration", not "the
   configuration is sent").

## How this applies to course material

- **Know which file you are in.** A module has a short landing page, a few
  deep-dive parts and a summary page. The landing page is a map: goals, what
  to know first, the order of the parts. The real teaching goes in the parts.
  The summary closes the module. A lab
  has a task, a step-by-step solution and a short intro. Keep each file to its
  job. Do not add "Prerequisite: ... Next: ..." navigation lines to pages;
  the landing page and the course outline already give the order.
- **Keep each part short.** One idea per part, about 5 to 8 minutes of
  reading and at most about 8 command blocks, so a learner can finish it with
  the playground in one sitting of about 15 minutes. Split at a natural seam
  where each half ends with something the learner has seen work. Never split
  only to hit a number. When you split, renumber the files, fix every "Part N"
  reference in the module and `astrona.yaml`.
- **Read like a book, not like a web page.** Each part reads as a chapter of
  a technical book. Open with a short paragraph on the problem it solves and
  why it matters. Link each paragraph to the next with a transition sentence.
  Close with a paragraph that sums up what the reader now knows and the
  question still open, before `## Common pitfalls` and the mission. Write
  explanations as prose; keep bullets for real lists (fields, ordered steps,
  options). Use `##` only when the topic changes and `###` only inside a long
  section, never for a single command. Weave hands-on steps into the text:
  one or two sentences on what to run and why, the command, the real output,
  then a sentence or two on what it shows.
- **The module ends with a summary.** The last page of every module is
  `course-0N-summary.md` with the title `# Summary`: a few short prose
  paragraphs on what the reader learned, organised by idea, optionally with
  one short list of key facts. It names no parts, modules, sections or
  chapters, and has no links, lab table, quiz or commands. Its last line is
  `<!-- astrona:playground:destroy -->` on its own line; the platform turns it
  into the step that removes the playground.
- **Every heading gets an intro.** A `##` section that has `###`
  subsections starts with one to three sentences that say what the section
  is about and why it matters, before the first `###`. Never put a `###`
  directly under a `##`.
- **Every module stands on its own.** Never refer to other sections or
  modules: no "see section 040", "as module 3 showed", "you met this in
  section 000", and no links to pages in another module. If the reader needs
  a fact from elsewhere, state the fact directly in one or two sentences.
  This also goes for parts of the same module: never write "Part 2 shows",
  "from Part 1" or "as in Part 3". Say the fact itself ("the commands below
  need the `scout` `DestinationRule` applied"). This includes the summary.
  The landing page does not have a "Where this fits" section.
- **Write words out in full.** Do not use informal short forms in prose:
  write "communications", "configuration", "repository", "administrator",
  "for example" and "that is", never "comms", "config", "repo", "admin",
  "e.g." or "i.e.". Names in code, commands and file paths stay as they are.
- **Exam terms stay.** The product's own names are what the reader must learn
  (for example a resource kind, a field, a command). Use them as they are and
  define each one in plain technical words the first time it appears in a
  file. Spell out acronyms on first use, with a short plain meaning.
- **The space theme is only for examples.** Space appears in two places and
  nowhere else: the names of the example workloads (the Starfleet: `bridge`,
  `scout`, `shuttle`, `probe`, the `starfleet` and `outpost` namespaces) and
  the short scenario that opens a lab task or a practice exercise (for
  example "the `drifter` in `outpost` must keep reaching the probe"). The
  explanation around an example is plain technical text: write "the
  `shuttle` pod sends a request to the `probe` Service", never "the shuttle
  sends a signal to the probe ship". Do not address the reader as an
  astronaut, and do not use space metaphors (communications officer, mission
  control, badge, airlock, guest list, star chart) for Istio or Kubernetes
  concepts. Titles of pages and labs name the technical task ("Require mTLS
  With PeerAuthentication"), not a space story.
- **Show one real example before the rule.** Start with a concrete case the
  reader can run, then give the general rule.
- **Say which part does the work.** Readers often mix up the parts of a system
  that sit close together. Whenever something happens, say which component
  did it.
- **Never change code to fit the style.** Commands, configuration files, field
  names, resource names, log lines and command output stay exactly as they
  are. They were run and checked on a real system. Never make up command
  output. If you shorten it, say that you did.
- **Prose only.** The grade-level and sentence rules apply to explanations.
  They do not apply to code blocks, tables of field names or reference lists
  (those may stay short and dense).
- **Keep the page furniture the same.** Hands-on steps are part of the prose
  (see "Read like a book"), not boxes or headings of their own. A `> [!TIP]` box is
  only for a real tip: advice the reader can reuse beyond this one step (a
  habit, a shortcut, how to spot a problem, an exam habit). Everything else
  is a normal sentence: notes about the current step ("if the log line is
  old, run it again"), background facts, optional extra steps, and plain
  information. Never a command snippet, never two in a row, and most pages
  need zero or one tip. Each part ends with a
  `## Common pitfalls` `> [!WARNING]` block for that part only. Use a Mermaid
  diagram for a flow, an order or a state change, keep it under about 12
  boxes, and follow it with one sentence that says what it shows.
- **Labs come right after the part they practise.** Do not collect all
  graded labs at the end of a module. In `astrona.yaml`, put each lab (its
  `question.md` reading and the `lab` entry) right after the reading part it
  tests. If a part teaches a gradeable skill and no lab covers it, create a
  new lab. That part then ends with a `## Your mission: <lab title>` section:
  one sentence on what the reader can now do, one on what the mission asks,
  then pause the playground (`astrona stop <playground name>`), the
  `astrona run` and `astrona submit` commands, and finally
  `astrona destroy <lab name>` plus `astrona start <playground name>`.
- **Renew the playground before hands-on work.** Every reading part that
  runs commands has `<!-- astrona:playground:renew -->` exactly once, on its
  own line, right before the first hands-on step (the first "Save this as"
  or the first command block), so the playground timer is reset before the
  learner needs the playground. Not on landing pages (they carry
  `<!-- astrona:playground -->`), summary pages (they carry
  `<!-- astrona:playground:destroy -->`) or pages without commands.
- **Mermaid without HTML.** The platform renders Mermaid with HTML labels
  switched off, so `<br/>` and any other HTML tag break the drawing. Rules:
  - One line per box, no `<br/>`, no HTML. Keep the box to the thing's name
    (`"scout-v2"`, `"istiod"`, `"Service: scout"`).
  - Put the logic on the arrows: `E -->|"version: v2"| P2`,
    `I -->|"CDS"| C`, `A -->|"end-user: jason"| B`. Keep edge labels short.
  - Quote every label. Prefer `flowchart TB`; use `LR` only for a short chain.
  - Sequence diagrams: short participant aliases (`participant S as shuttle`)
    and short message text.
  - Anything longer (cluster names, full hostnames) goes in the sentence under
    the diagram.
- **Every course starts with an Introduction.** It lives in `sections/intro/`
  and is the first entry in `astrona.yaml` (`id: module-intro`, title
  "Introduction"). It has exactly these four pages, in this order:
  - `README.md`, `# Introduction`: what the introduction covers and its three
    pages, named in prose (no links), ending with the topic the course starts
    with.
  - `course-01-welcome.md`, `# Welcome To The Course`: who the course is for,
    the exam domain and what the reader can do at the end, the words the
    course uses, the example app, how the course is laid out and how to read
    a page.
  - `course-02-get-your-machine-ready.md`, `# Get Your Machine Ready`: the
    tools to install, the `astrona` commands used every day, and what to do
    when a start goes wrong.
  - `course-03-how-this-course-is-made.md`, `# How This Course Is Made`: how
    content is written and checked, the maintainers, how to report a mistake,
    and the license.
  The Introduction teaches no product content and has no playground, labs or
  summary. Its only links are the repository's contributors page, issues
  page and license.
- **No links to other course files.** A course page (every reading listed in
  `astrona.yaml`, the playground guide `docs/overview.md`, and a lab's
  `question.md` and `solution.md`) never links to or points the reader at
  another page or file of the repository: no links to parts, summaries,
  labs, `question.md`, other modules, sections or the Introduction, and no
  "see `practice.md`" or "open `config.yaml`". The platform shows the pages in
  the order of `astrona.yaml`, so a link only adds a second, often wrong,
  path. Name a thing in plain words when the reader needs it ("the task is on
  the next page"), and state a fact on the page itself instead of sending the
  reader somewhere else. Repository files for authors (the root `README.md`,
  a lab's or playground's `README.md`) may link.
- **No links to outside sources.** Course pages, labs and playground docs do
  not link to or point at outside websites (the one exception is the
  `resources` field of a lab entry in `astrona.yaml`) (official docs, GitHub, blogs,
  RFCs), and they have no "Reference" or "Official docs" lists. Everything the
  reader needs is explained on the page itself. Not affected: addresses the
  reader actually uses in a command or browser (`http://127.0.0.1:9080`,
  `curl https://httpbin.org`), and the Introduction's contributors and
  "report a mistake" links.
- **Configuration goes to a file first.** Whenever the reader should apply
  YAML (course parts, playground docs, labs), use three separate steps:
  1. "Save this as `virtualservice-scout.yaml`:" followed by a plain
     ` ```yaml ` block with only the YAML. No `cat > file <<'EOF'`, no
     `kubectl apply -f - <<EOF`, no shell around it.
  2. "Apply it:" followed by a ` ```sh ` block with only
     `kubectl apply -f virtualservice-scout.yaml`.
  3. "Then check the result:" followed by the check commands, if any.
  The file name says the kind and the object. If a value must come from the
  reader's cluster (an IP address), use a placeholder like `<PARTNER>` in the
  YAML and say how to get the value (`echo $PARTNER`); never put shell
  variables inside YAML. Apply an object the first time its YAML appears; do
  not show it once "to read" and paste it again later. Never tell the reader
  to apply something from the playground's `examples/` folder: they start the
  playground with `astrona run`, so that folder is not on their machine.
- **Helpers have readable names.** Shell helper functions and variables use
  names that say what they do (`check_route`, `count_versions`,
  `$SERVICE_URL`), never single letters.


## About this repo (ATS114 only)

Everything above is general and can be copied to other course repositories. This
section is only true for this one.

### What the student is trying to learn

- **The goal:** master the **Secrets Engines & Dynamic Credential Lifecycle**
  domain of the **OpenBao** training path (`ATP022`). It is 25% of the path.
  There is no official OpenBao certification exam; the path's domains and
  weights are Astrona's own, set in `ATP022/path.yaml`.
- **What the domain really tests:** issuing and managing secrets with the
  `bao` command-line tool: store and recover versioned static secrets, run an
  internal certificate authority, hand out database credentials that expire,
  encrypt data without storing it, and clean up leases. Every explanation
  should lead to a command the reader can run, and every fix should be proved
  with a secret, certificate or credential that works (or stops working) as
  expected.
- **The four topics:** static secrets in KV version 2, certificates with the
  PKI engine, dynamic database credentials and their leases, and encryption
  as a service with the Transit engine.
- **The sections:**

  | Section | Title | Topic |
  | --- | --- | --- |
  | 010 | Static Secrets With KV Version 2 | KV v2 |
  | 020 | Certificates With The PKI Engine | PKI |
  | 030 | Dynamic Database Credentials | Database engine and leases |
  | 040 | Encryption As A Service With Transit | Transit |

- **The versions:** **OpenBao v2.7.1** (server image `quay.io/openbao/openbao`
  and the `bao` CLI from the release archive), installed with the `openbao`
  Helm chart **0.30.4** (`appVersion` v2.7.1) and Helm **3.22.1** on a
  single-node `kind` cluster; **PostgreSQL 17** (`postgres:17-alpine`) as the
  database for section 030. The documentation version is 2.7.x. Do not teach
  fields, flags or output from other versions without saying so.
- **The main sources:** the OpenBao documentation, <https://openbao.org/docs/>,
  and the source of `openbao/openbao` at tag `v2.7.1` (the docs are under
  `website/content/docs/`: `secrets/kv/kv-v2.mdx`, `secrets/pki/*`,
  `secrets/databases/index.mdx` and `postgresql.mdx`,
  `secrets/transit/index.mdx`, `concepts/lease.mdx`, `commands/kv/*`,
  `commands/lease/*`). Check every page against them.
- **OpenBao is not Vault.** OpenBao is a fork of HashiCorp Vault 1.14 under
  the Linux Foundation (LF Projects, an OpenSSF sandbox project). Use OpenBao
  names (`bao`, `BAO_ADDR`, `BAO_TOKEN`). One Vault name stays on purpose:
  Transit ciphertext still starts with `vault:v1:`, as the OpenBao
  documentation shows; explain it the first time it appears in a file.

### Status: built, not yet run

The first version of this repository was written from the OpenBao 2.7
documentation **without a live run**. No playground or lab has been started,
and no `astrona test` has passed yet. Until a maintainer runs them:

- Pages describe results in words. Do not add `text` output blocks until the
  output comes from a real run, and then paste it exactly.
- Treat every lab as unverified. Run `astrona validate` and `astrona test` on
  each one, one cluster at a time, before the course goes past `maturity:
  draft`.
- Remove this subsection when every lab has passed `astrona test`.

The facts most likely to be wrong, in order (check these first):

1. **PostgreSQL privileges for the connection user.** The connection user
   `openbao_admin` has `CREATEROLE` and `SELECT ... WITH GRANT OPTION` on the
   tables, but is not a superuser. On PostgreSQL 16 and later a `CREATEROLE`
   user can drop only roles it created; the default revocation should work,
   but it is unverified.
2. **The KV metadata JSON shape** that graders read with `jq`
   (`.data.versions["1"].created_time`, `.data.versions["3"].destroyed`,
   `.data.max_versions`, `.data.cas_required`, `.data.current_version`), and
   the mount configuration endpoint `secret/config`.
3. **PKI responses:** `pki/cert/ca` and `pki_int/cert/ca` return the CA
   certificate in `.data.certificate`; `pki/ca/pem` answers without a token.
4. **Transit key information** (`.data.latest_version`,
   `.data.min_decryption_version`, `.data.keys["1"]` as a creation time).
5. **Lease listing:** `bao list sys/leases/lookup/database/creds/<role>/`
   returns the lease IDs, and answers `404` (an error) when none remain.

### Terms, not metaphors

| Term | First-use definition (example wording) |
| --- | --- |
| Secrets engine | A component OpenBao enables at a path (a mount) that stores, generates or encrypts data, for example `kv-v2`, `pki`, `database`, `transit` |
| Static secret / dynamic secret | A value someone stored and OpenBao only returns / a value OpenBao creates on request, with a lease, and can revoke |
| KV version 2 | The key/value engine that keeps a numbered version of every write; data lives under `<mount>/data/`, settings under `<mount>/metadata/` |
| Soft delete / destroy / undelete | Mark a version deleted but keep its data / remove a version's data for good / clear the deleted mark |
| Rollback | Write an older version's data again as a new, current version |
| Check-and-set (CAS) | A write that succeeds only if the caller names the current version number |
| Certificate authority (CA) | A key and certificate that signs other certificates; clients trust the CA, so they trust what it signs |
| Root CA / intermediate CA | The top CA, kept for signing other CAs / a CA signed by the root that signs service certificates |
| Issuer | One CA certificate and key inside a PKI mount |
| PKI role | A named rule set on a PKI mount that says which names and lifetimes a certificate may have |
| Certificate revocation list (CRL) | A signed list of certificates the CA has revoked |
| Database connection / database role | The settings OpenBao uses to reach a database as an administrative user / the SQL OpenBao runs to create a user, and that user's lifetime |
| Static role (database) | A database user that already exists; OpenBao only rotates its password |
| Root credential rotation | OpenBao changes the password of its own connection user, so nobody else knows it |
| Lease | The time a dynamic secret is valid, with an ID; it can be renewed or revoked |
| Transit key / key version | A named encryption key that never leaves OpenBao / one generation of it, created by a rotation |
| Rewrap | Re-encrypt a ciphertext with the newest key version without returning the plaintext |
| `min_decryption_version` | The oldest key version Transit still decrypts with |

### The example workloads

| Name | What it is |
| --- | --- |
| OpenBao (namespace `openbao`, Helm release `openbao`) | OpenBao v2.7.1, pod `openbao-0`, Service `openbao` on port `8200`, Integrated Storage (`raft`), no TLS (lab-only). Every environment starts **initialized and unsealed** (`INIT_MODE=unsealed`) |
| Secret `openbao-init` (namespace `openbao`) | The lab-only unseal key (`unseal-key`) and root token (`root-token`). Pages read the root token from it and say that a real installation never keeps these in a Kubernetes Secret |
| `tester` (namespace `clients`) | `nicolaka/netshoot:v0.13` with `curl`, `jq` and `openssl`; graders verify certificates and call the API from here |
| PostgreSQL (namespace `data`, sections 030 and capstone 040) | `postgres:17-alpine`, Service `postgres` on port `5432`, database `inventory` with the table `items`. Lab-only users: `postgres` / `postgres-admin-password` (superuser, never given to OpenBao) and `openbao_admin` / `openbao-admin-password` (`CREATEROLE`, the user OpenBao connects as) |

Inside OpenBao the pages use the same names everywhere: the KV mount
`secret/` with secrets under `inventory/`, the PKI mounts `pki/` (root CA
"Inventory Root CA") and `pki_int/` (intermediate CA "Inventory Intermediate
CA"), the role `inventory-svc` for names under `inventory.svc`, the database
mount `database/` with the connection `inventory-db` and the role
`inventory-readonly`, and the Transit mount `transit/` with the key
`inventory-records`.

### Environment facts the text must respect

- **One address everywhere: `http://openbao.localtest.me:8200`.** Inside the
  cluster a CoreDNS `rewrite stop` block (with the answer name rewritten back)
  sends the name to `openbao.openbao.svc.cluster.local`. On the reader's
  machine, `kubectl -n openbao port-forward svc/openbao 8200:8200` makes it
  answer there, and pages set `export BAO_ADDR=http://openbao.localtest.me:8200`.
  The CoreDNS block is the one in every `bootstrap/prepare.sh` and
  `bootstrap/01-install-openbao.sh`; never the one-line `rewrite name` form.
  If the name does not resolve on the reader's machine, they add
  `127.0.0.1 openbao.localtest.me` to `/etc/hosts`.
- **The reader's token.** Pages set
  `export BAO_TOKEN=$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)`
  and say that the root token is used only because this is a lab; the policies
  that replace it are taught in the policies course.
- **The `bao` CLI runs on the reader's machine**, installed pinned by the
  environment. Scripts use the `bao` in the server image through
  `kubectl -n openbao exec -i openbao-0 -- env BAO_ADDR=http://127.0.0.1:8200 BAO_TOKEN=... bao ...`.
- **Every pod restart seals OpenBao again.** The install script unseals it
  with the key from `openbao-init`; no module restarts the pod on purpose.
- **PostgreSQL is reached as `postgres.data:5432` from OpenBao.** Readers and
  graders run `psql` inside the PostgreSQL pod
  (`kubectl -n data exec -i deploy/postgres -- env PGPASSWORD=... psql -h 127.0.0.1 -U <user> -d inventory`).
- **Certificates are checked with `openssl` in `tester`.** The root and
  intermediate certificates are fetched from `/v1/pki/ca/pem` and
  `/v1/pki_int/ca/pem`, which need no token.
- **Many environments start broken on purpose.** A lab seeds a fault (a bad
  KV write, an intermediate CA that was never signed, a role with a lease of
  a month, ciphertexts on an old key version). The fault is the material.
  Never "fix" it in the bootstrap.

### Where things are in this repo

The layout is the same as every Astrona course: `astrona.yaml`, `README.md`,
`sections/intro/`, `sections/section-0N0/README.md`, module pages
(`course.md`, `course-0N-*.md`), `playground/` (`config.yaml`,
`bootstrap/prepare.sh`, `manifests/openbao-values.yaml`,
`manifests/lab-start.yaml`, `docs/overview.md`), labs (`config.yaml`,
`README.md`, `prerequisites.md`, `question.md`, `solution.md`,
`bootstrap/01-install-openbao.sh`, `bootstrap/02-seed-state.sh`,
`manifests/`, `solution/apply.sh`, `testing/wait-for-openbao.sh`,
`validation/validate-*.sh`) and one capstone per section.

The shared plumbing of the 12 environments (install scripts, manifests,
`config.yaml` files, author READMEs, `prerequisites.md`, the helper block at
the top of seed, solution and validation scripts) was generated from one
script that is not kept in this repository. When you change a shared piece
(the CoreDNS block, the `bao_root` helper, the PostgreSQL manifest), change it
in **every** environment.

### Lab metadata in `astrona.yaml`

`training:` block: id `ATS114`, domain `Secrets Engines & Dynamic Credential
Lifecycle`, weight `25`. Lab entries carry `title`, `path`, `difficulty`,
`estimated_duration`, `topic`, `task_kind`, `tags`, `learning_goals`,
`resources`, in that order, as in ATS016.

- `topic`: exactly one of `kv`, `pki`, `database`, `leases`, `transit`.
- `task_kind`: `build`, `troubleshooting` or `migration`.
- `tags`: 4 to 8, only from this list: `kv-v2`, `versions`, `soft-delete`,
  `destroy`, `undelete`, `rollback`, `kv-metadata`, `check-and-set`,
  `max-versions`, `pki`, `root-ca`, `intermediate-ca`, `csr`, `pki-role`,
  `issue-certificate`, `crl`, `issuing-urls`, `openssl`, `database-engine`,
  `postgresql`, `dynamic-credentials`, `database-role`, `rotate-root`,
  `static-role`, `lease`, `lease-renew`, `lease-revoke`, `revoke-prefix`,
  `ttl`, `transit`, `encrypt`, `decrypt`, `key-rotation`, `rewrap`,
  `min-decryption-version`.
- `resources`: 1 to 4 pages on `openbao.org`. The only place outside links
  are allowed.

### Running things

```bash
astrona run --git ssh://git@github.com/astrona-io/ATS114.git -c sections/section-010/module-01/playground
astrona destroy ats-114-playground-010-01
astrona run --git ssh://git@github.com/astrona-io/ATS114.git -c sections/section-010/module-01/labs/lab-01
astrona submit -c sections/section-010/module-01/labs/lab-01
astrona destroy ats-114-lab-010-01
astrona test -c sections/section-010/module-01/labs/lab-01   # authors
```

Names: `ats-114-playground-<section>-<module>`, `ats-114-lab-<section>-<module>`,
`ats-114-capstone-<section>`. Graders check **behaviour** (the current KV
version holds the right data, a certificate verifies against the chain, a
database user can log in and is gone after revocation, ciphertext decrypts to
the original plaintext) and reject the plausible but wrong fix (deleting and
rewriting a secret instead of recovering it, issuing service certificates
from the root CA, giving OpenBao the PostgreSQL superuser, re-creating a
Transit key instead of rotating it). A lab's `question.md` and `solution.md`
must match what its `validation/` scripts check.

### Where to find trusted sources

- **KV version 2:** <https://openbao.org/docs/secrets/kv/kv-v2/>, the
  `bao kv` command pages
- **PKI:** <https://openbao.org/docs/secrets/pki/>, the root and
  intermediate quick starts, <https://openbao.org/docs/secrets/pki/considerations/>
- **Databases:** <https://openbao.org/docs/secrets/databases/>,
  <https://openbao.org/docs/secrets/databases/postgresql/>
- **Transit:** <https://openbao.org/docs/secrets/transit/>
- **Leases:** <https://openbao.org/docs/concepts/lease/>,
  <https://openbao.org/docs/commands/lease/revoke/>
