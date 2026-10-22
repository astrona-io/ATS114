# Section 040: Encryption As A Service With Transit

Applications often store data that must be encrypted: customer details, order notes, tokens from other systems. Writing encryption code is easy to get wrong, and keeping the key next to the data defeats the point. The Transit secrets engine does the cryptography for the application: it encrypts and decrypts with keys that never leave OpenBao, and it stores none of the data.

This section uses one Transit key from creation to retirement: encrypt and decrypt records, rotate the key, rewrap stored ciphertext to the new version, and finally stop the old versions from decrypting anything.

**Topic covered:** Transit

## What you will learn

- What encryption as a service means, and why Transit stores no data.
- Creating a named key, encrypting and decrypting Base64 data, and reading the ciphertext format `vault:v1:`.
- Data keys for encrypting large data in the application.
- Rotating a key, and what happens to data encrypted with older versions.
- Rewrapping ciphertext to the newest key version without seeing the plaintext.
- Retiring old key versions with `min_decryption_version`.

## The learning path

The module starts at its landing page, which also launches the playground. The playground holds OpenBao, initialized and unsealed, with no Transit mount yet.

### 1. Encrypt Data With The Transit Engine

1. Encryption As A Service
2. Key Rotation, Rewrap And Retiring Old Versions, followed by the lab **Rewrap Records And Retire Old Key Versions**
3. Summary

## Section capstone: Rotate Everything After A Leak

The capstone combines the Transit engine with the other engines of this course. A backup with a debug dump leaked: it held a KV secret with an extra field, records encrypted with the first version of a Transit key, and four database credentials. Remove the KV leak, retire the leaked key version, and revoke the credentials. The capstone needs PostgreSQL, which it starts for you.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS114.git -c sections/section-040/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-040/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-114-capstone-040
```
