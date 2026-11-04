# Summary

A mount is the path where an engine is attached. OpenBao's router reads the first segment of every request path and sends the request to the engine mounted there. `bao secrets list -detailed` shows the mount table with the type, accessor, description and options of each mount. The same engine can be mounted many times, and every mount has its own data and settings.

Tuning changes the settings of one mount. `default_lease_ttl` is the lifetime a lease gets when nothing else asks for one, and `max_lease_ttl` is the ceiling. A value of `0` means that the system value applies, and a non-zero mount value takes the place of the system value for that mount. A request is also capped by the role maximum.

Moving a mount with `bao secrets move` keeps its data, settings and accessor but changes the path, so applications and policies must be updated, and leases on the mount are revoked. Disabling a mount with `bao secrets disable` deletes everything in it for good. KV version 1 keeps one value per path and uses plain paths. KV version 2 keeps versions and uses `data/` and `metadata/` paths, and a version 1 mount can be upgraded to version 2 with `bao kv enable-versioning` but not back. The key facts to remember are these:

- Move keeps data; disable destroys it.
- A mount value replaces the system value for that mount only.
- Policies name paths, so a move or an upgrade needs a policy update.
- Enable new KV mounts as `kv-v2`.

<!-- astrona:playground:destroy -->
