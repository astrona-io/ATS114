# Section 050: TOTP And SSH Engines

Two more engines cover access to people and servers. The TOTP engine generates and validates time-based one-time codes, the same kind that authenticator apps show. The SSH engine signs short-lived SSH certificates, or hands out one-time passwords, so servers do not keep permanent public keys.

This section configures both engines, limits them with roles and policies, and finishes with an audit that tightens an over-open SSH role and replaces a leaked TOTP key.

**Topic covered:** TOTP and SSH

## What you will learn

- How TOTP derives a code from a secret and the time, and which settings must match on both sides.
- Generating a key, importing a secret, and validating codes.
- The provider and consumer modes of the TOTP engine, and the policies that separate them.
- Enabling the SSH engine, generating a CA key and trusting it on a server.
- Writing a CA role and signing a public key, and reading the certificate.
- Restricting principals, lifetimes, extensions and critical options.
- One-time password mode, and how a server verifies a password.

## The learning path

Each module starts at its landing page, which also launches its playground. The playgrounds hold OpenBao, initialized and unsealed, with the engine of that module not enabled yet.

### 1. Time-Based One-Time Passwords With The TOTP Engine

1. How TOTP Works
2. Generating And Validating Codes
3. Provider And Consumer Modes
4. Access Control And Operations, followed by the lab **Set Up Time-Based One-Time Passwords**
5. Summary

### 2. SSH Certificates And One-Time Passwords With The SSH Engine

1. Two Ways To Authenticate
2. Signing User Keys With A CA Role
3. Restricting A Role
4. One-Time Passwords, followed by the lab **Configure An SSH Certificate Authority Role**
5. Summary

## Section capstone: Lock Down SSH And TOTP After An Audit

An audit found an SSH role that signs for any principal for 720 hours, and a TOTP secret that was pasted into a ticket. Restrict the role, replace the TOTP key, and write a policy that lets a token sign only through that role.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS114.git -c sections/section-050/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-050/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-114-capstone-050
```
