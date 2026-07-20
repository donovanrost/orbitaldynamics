# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema field-type hint catalog extraction.

Status:
Selected; implementation pending.

Selected boundary:
Extract the static JSON-schema field-type hint map from `Schema` into a focused
compile-time `FieldTypeHints` catalog. Keep the facade's `@field_type_hints`
snapshot and default-property dispatch input unchanged.

Selection evidence:
- `schema.ex` remains the dominant production hotspot at 4,614 lines; the other
  targeted public facades are now 164 to 524 lines.
- The facade owns roughly 800 lines of static field-name to JSON-type metadata
  used at one default-property dispatch boundary.
- The map has no facade callbacks or runtime state and is already consumed as a
  compile-time snapshot.
- Moving it creates one authoritative schema-metadata catalog without changing
  public APIs.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. Every hint key/value, duplicate-key resolution semantics,
compile-time snapshot behavior, public `Schema`, generated schemas, and
checked-in exports must remain unchanged.

Last completed slice:
Schema result-artifact validation owner extraction, selected in `b2c2ddfe` and
implemented in `0c3e0f97`. `schema.ex` moved from 4,627 to 4,614 lines.

Next candidate:
Implement and verify the selected field-type hint catalog extraction, then
re-rank the remaining JSON-schema property dispatch and schema-builder blocks.

Blocked:
No.
