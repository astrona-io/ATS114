# Summary

The Transit secrets engine is encryption as a service. The application sends Base64 plaintext to `transit/encrypt/<key>` and gets ciphertext back; it stores the ciphertext itself and sends it to `transit/decrypt/<key>` when it needs the plaintext. The key never leaves OpenBao and is not exportable by default, and OpenBao stores none of the data, so a leaked database without OpenBao holds only ciphertext.

Every ciphertext starts with `vault:vN:`. The `vault` prefix is kept from the project OpenBao was forked from, and `vN` names the key version that encrypted it. Every encryption uses a new random initialization vector, so equal plaintexts give different ciphertexts. For data too large to send through the API, a data key from `transit/datakey/` lets the application encrypt locally and store the data key encrypted next to the data.

A key changes in three steps. A rotation adds a new version to the key ring; new encryptions use it and old versions still decrypt. A rewrap re-encrypts stored ciphertext with the newest version inside OpenBao, without returning the plaintext, and the application must save the result. Only when every stored ciphertext uses the newest version does raising `min_decryption_version` retire the old versions; they are archived and can be brought back until a trim removes them for good. The key facts to remember are these:

- Base64 on the way in, Base64 on the way out.
- Rotate, rewrap and save, then raise `min_decryption_version`, in that order.
- Never delete and re-create a key to "rotate" it; the old ciphertext becomes unreadable.
- `bao operator rotate` rotates OpenBao's barrier key, not a Transit key.

<!-- astrona:playground:destroy -->
