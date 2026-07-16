# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Completed: primitive type validation support extraction.

Status:
Published.

Selected slice:
Move required/optional type checks into `Schema.PrimitiveValidation` while
retaining the facade's existing local call and callback shapes through an
explicit import.

Why this slice:
The three related type checks and private matcher form the smallest
self-contained boundary inside the remaining generic primitive tail.

Current coupling/problem:
Resolved for primitive types: map/list/string/boolean/integer checks now live
together outside the large public facade.

Public facade preserved:
- `OrbitalDynamics.Schema.validate_artifact/2`
- `OrbitalDynamics.Schema.validation_report/2`
- All existing contract-specific validation behavior and error shapes.

Extraction target:
`OrbitalDynamics.Schema.PrimitiveValidation`.

Files changed:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/primitive_validation.ex`

Behavior/schema changes:
None. Validation branches and error maps/messages were moved mechanically.

Tests run:
- `mix compile --warnings-as-errors` passed.
- Broad schema, resource-contract, invalid contact filter/contention ID, and
  schema export coverage passed: 92 tests.
- SHA-256 over `{Schema.contracts(), Schema.json_schema_bundle()}` remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`.
- Xref showed the expected facade export edge and an outbound-dependency-free
  helper.
- Formatting, whitespace, new-file review, and checked-in-schema cleanliness
  checks passed.

Verification gaps:
- The full suite was not run for this internal extraction.

Last commit:
`538b3652` (`Extract primitive type validation support`).

Next candidate:
Extend the cohesive primitive support boundary with scalar number, integer, and
probability checks that only depend on local error construction.

Blocked:
No.

Notes:
- `schema.ex` decreased from 15,034 to 14,998 lines.
- `PrimitiveValidation` is 46 lines.
- Parent review found no must-fix findings; parent publishing is the active-mode
  fallback because subagent delegation is unavailable.
- The facade remains substantial; this is not a completion claim.
