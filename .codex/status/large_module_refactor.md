# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Completed: generic primitive validation extraction.

Status:
Published.

Selected slice:
Move required-field, nested-object, number-vector, interval, and shared error
primitives into `Schema.PrimitiveValidation` behind explicit imports.

Why this slice:
These were the remaining self-contained generic validation primitives at the
end of the facade and complete the support module's responsibility boundary.

Current coupling/problem:
Resolved for generic primitives. The facade tail now ends with artifact-specific
validation adapters rather than generic field/type/collection/error helpers.

Public facade preserved:
- `OrbitalDynamics.Schema.validate_artifact/2`
- `OrbitalDynamics.Schema.validation_report/2`
- All callback arities, validation ordering, and error maps/messages.

Files changed:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/primitive_validation.ex`

Behavior/schema changes:
None. Required-field, vector, interval, and error behavior moved mechanically.

Tests run:
- `mix compile --warnings-as-errors` passed.
- Broad schema, resource-contract, invalid contact filter/contention ID, and
  schema export coverage passed: 92 tests.
- SHA-256 over `{Schema.contracts(), Schema.json_schema_bundle()}` remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`.
- Xref showed the expected facade export edge and an outbound-dependency-free
  helper.
- Formatting, whitespace, tail/diff review, and checked-in-schema cleanliness
  checks passed.

Verification gaps:
- The full suite was not run for this internal extraction.

Last commit:
`8b680881` (`Complete primitive validation extraction`).

Next candidate:
Assess the adjacent generic row/map collection helpers beginning with
`validate_rows/4` as the next cohesive support extraction.

Blocked:
No.

Notes:
- `schema.ex` decreased from 14,768 to 14,731 lines.
- `PrimitiveValidation` increased from 268 to 307 lines.
- Parent review found no must-fix findings; parent publishing is the active-mode
  fallback because subagent delegation is unavailable.
- The facade remains substantial; this is not a completion claim.
