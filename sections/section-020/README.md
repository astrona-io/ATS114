# Section 020: Certificates With The PKI Engine

Every service that talks TLS needs a certificate, and every certificate needs a certificate authority (CA) that the clients trust. Buying a certificate for each internal service is slow and expensive, and a self-signed certificate per service teaches clients to trust anything. The PKI secrets engine turns OpenBao into an internal CA that issues short-lived certificates on request.

This section builds the usual two-tier hierarchy: a root CA that signs one intermediate CA, and an intermediate CA that signs the service certificates. It ends with roles that limit which names and lifetimes a certificate may have, and with revocation.

**Topic covered:** PKI

## What you will learn

- What a CA, a certificate signing request (CSR) and a certificate chain are, and why the root CA signs only an intermediate.
- Enabling the PKI engine, tuning its maximum lease time, and generating a root CA.
- Generating an intermediate CA, signing its CSR with the root, and installing the signed certificate.
- Writing a role with allowed domains, subdomains and a maximum lifetime, and issuing certificates from it.
- Checking a certificate and its chain with `openssl`.
- Setting the issuing certificate and CRL URLs, revoking a certificate and reading the certificate revocation list (CRL).

## The learning path

The modules start at their landing pages, which also launch their playgrounds. Each playground holds OpenBao, initialized and unsealed, with the engine of that module not set up yet.

### 1. Run An Internal Certificate Authority With The PKI Engine

1. The PKI Engine And A Root CA
2. An Intermediate CA Signed By The Root
3. Roles, Issuing Certificates And Revocation, followed by the lab **Build A Two-Tier CA For The Inventory Services**
4. Signing Requests And Inspecting Certificates
5. Summary

### 2. Issuers And Root Rotation In The PKI Engine

1. Issuers And Keys
2. The Default Issuer And Roles
3. Rotating A Root CA, followed by the lab **Rotate The Root Issuer Of A PKI Mount**
4. Retiring An Issuer
5. Summary

### 3. Certificate Revocation, OCSP And Tidy In The PKI Engine

1. Revoking Certificates And Reading The CRL
2. Configuring The CRL
3. OCSP And The URLs In A Certificate
4. Tidy And Auto-Tidy, followed by the lab **Configure CRL, OCSP And Tidy For A PKI Mount**
5. Summary

## Section capstone: Repair A Broken Certificate Chain

The capstone is one graded scenario that combines the whole section. Someone started the inventory CA hierarchy and stopped half-way: the intermediate CA was never signed, its role allows the wrong domain, a role sits on the root mount, and certificates carry no URLs. Work it after the module labs.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS114.git -c sections/section-020/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-020/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-114-capstone-020
```
