# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema executable-registry catalog extraction.

Status:
Selected; implementation pending.

Selected boundary:
Extract the full executable contract map composition from `Schema` into a
focused `RegistryCatalog` module. Keep `Schema`'s compile-time `@contracts`
snapshot and every public registry API unchanged while establishing one
non-facade source for later capability-catalog validation ownership.

Selection evidence:
- `schema.ex` remains the dominant production hotspot at 4,712 lines; the other
  targeted public facades are now 164 to 524 lines.
- The facade currently owns about 80 lines of mechanical registry-map assembly
  used by every public contract, schema, and validation path.
- The capability-catalog validator is the only remaining direct clause that
  needs the full registry, so duplicating this assembly in a validator would
  create drift risk.
- A compile-time catalog snapshot preserves current semantics and removes no
  public API.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. Registry merge order and contents, compile-time snapshot
semantics, all public `Schema` APIs, validation results, and checked-in exports
must remain unchanged.

Last completed slice:
Schema activity-artifact owner extraction, selected in `ce7e1eca` and
implemented in `65e3a783`. `schema.ex` moved from 4,722 to 4,712 lines.

Next candidate:
Implement and verify the selected registry catalog extraction, then assess
capability-catalog validation ownership against that new boundary.

Blocked:
No.
