# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema validation leaf-schema direct routing.

Status:
Completed and pushed.

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
Removed the six validation-family leaf-schema helpers and routed all eight
consumers directly to their three existing owner modules. `schema.ex` moved
from 6,061 to 6,039 lines.

Verification:
- Strict focused validation/lint/export baseline before routing: 13 passed.
- The same strict focused suite after routing: 13 passed.
- Strict registry, full JSON Schema export-contract, and validation-policy
  coverage: 21 passed.
- The full schema-export task completed and produced no checked-in changes.
- `mix xref callers` for ValidationJsonSchema,
  SchemaMigrationReportJsonSchema, and SchemaValidationReportJsonSchema
  reports the expected facade and internal-owner consumers.
- Static search confirms all six helper definitions and indirect references are
  gone.
- `git diff --check` passed.
- Strict forced compile passed across 4,065 files.
- Implementation commit `6a23e82b` pushed to `main`.

Behavior/schema changes:
None. Public facades, callback timing, validation leaf and composed schemas,
executable validation, and checked-in exports remain unchanged.

Last completed slice:
Schema validation leaf-schema direct routing, selected in `47e7ed05`, boundary
count corrected in `fb47f7a9`, and implemented in `6a23e82b`.
`schema.ex` moved from 6,061 to 6,039 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters now that
direct domain capability reads have been removed from the facade.

Blocked:
No.
