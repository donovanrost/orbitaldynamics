# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema field-type hint catalog extraction.

Status:
Complete and pushed.

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
Added an 803-line compile-time `FieldTypeHints` catalog containing the unchanged
795-entry map, then replaced the facade table with one catalog call. `schema.ex`
moved from 4,614 to 3,818 lines.

Verification:
- Strict JSON-schema, registry, default-property, and export baseline: 32 tests
  passed.
- Entire schema test directory plus export coverage: 178 tests passed.
- The extracted source block matched the selected revision byte-for-byte and
  the compiled map contains the same 795 entries.
- Full schema export regenerated with no checked-in schema artifact changes.
- Formatting, diff whitespace, bounded dependency/reference checks, and the
  bounded semantic diff review passed.
- `MIX_ENV=test MIX_OS_CONCURRENCY_LOCK=0 mix compile --force
  --warnings-as-errors` compiled 4,092 files successfully.

Behavior/schema changes:
None. Every hint key/value, duplicate-key resolution semantics, compile-time
snapshot behavior, public `Schema`, generated schemas, and checked-in exports
remain unchanged.

Last completed slice:
Schema field-type hint catalog extraction, selected in `da2eac26` and
implemented in `bc19058a`. `schema.ex` moved from 4,614 to 3,818 lines.

Next candidate:
Re-rank the remaining JSON-schema property dispatch and schema-builder blocks
against the now substantially smaller facade.

Blocked:
No.
