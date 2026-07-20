# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema validation leaf-schema direct routing.

Status:
Selected; implementation not started.

Selected boundary:
Remove six zero-context, one-hop leaf-schema helpers for validation issues,
lint issues, remediation rows, validation checks, migration rows, and skipped
artifacts. Route their eight facade consumers directly to the existing
ValidationJsonSchema, SchemaMigrationReportJsonSchema, and
SchemaValidationReportJsonSchema owner APIs. Keep dispatch, composed report
schemas, executable validation, and all public facades in
`OrbitalDynamics.Schema`.

Selection evidence:
- `schema.ex` remains the dominant hotspot at 6,061 lines.
- All six helpers call zero-arity owner APIs and add no facade state, guards,
  defaults, transformation, or caching.
- The callback consumers can capture the owners directly; the one eager
  validation-check consumer can call the same owner directly.
- Final pre-edit occurrence counting confirms eight consumers: seven lazy
  callbacks and one eager validation-check composition.
- Exact leaf schemas, callback timing, composed JSON Schema, validation
  results, and checked-in exports must remain unchanged.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
Schema relay-data-path assumptions direct routing, selected in `ba6c7206` and
implemented in `1d20cd05`.
`schema.ex` moved from 6,065 to 6,061 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters now that
direct domain capability reads have been removed from the facade.

Blocked:
No.
