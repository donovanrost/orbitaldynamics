# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Completed: primitive collection validation support extraction.

Status:
Published.

Selected slice:
Move enum/equality, list-item, and optional-field collection checks into
`Schema.PrimitiveValidation` behind explicit facade imports.

Why this slice:
These helpers are one cohesive collection-validation family and depend on the
type/numeric primitives already extracted into the same internal module.

Current coupling/problem:
Resolved for generic collections: enum, list-item, and repeated optional-field
checks now live with their primitive dependencies.

Public facade preserved:
- `OrbitalDynamics.Schema.validate_artifact/2`
- `OrbitalDynamics.Schema.validation_report/2`
- All existing callback arities, ordering, and error maps/messages.

Files changed:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/primitive_validation.ex`

Behavior/schema changes:
None. Validation branches, ordering, and exact error maps/messages were moved.

Tests run:
- `mix compile --warnings-as-errors` passed.
- Broad schema, resource-contract, invalid contact filter/contention ID, and
  schema export coverage passed: 92 tests.
- SHA-256 over `{Schema.contracts(), Schema.json_schema_bundle()}` remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`.
- Xref showed the expected facade export edge and an outbound-dependency-free
  helper.
- Formatting, whitespace, diff review, and checked-in-schema cleanliness checks
  passed.

Verification gaps:
- The full suite was not run for this internal extraction.

Last commit:
`9be76d6e` (`Extract primitive collection validation support`).

Next candidate:
Move the remaining required-field, vector, interval, and shared error primitives
to complete the generic validation-support boundary.

Blocked:
No.

Notes:
- `schema.ex` decreased from 14,923 to 14,768 lines.
- `PrimitiveValidation` increased from 132 to 268 lines.
- Parent review found no must-fix findings; parent publishing is the active-mode
  fallback because subagent delegation is unavailable.
- The facade remains substantial; this is not a completion claim.
