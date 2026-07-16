# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Completed: primitive numeric validation support extraction.

Status:
Published.

Selected slice:
Move scalar number, integer, and probability checks into
`Schema.PrimitiveValidation` while retaining existing local call and callback
shapes through explicit imports.

Why this slice:
The seven scalar checks only depend on local error construction and naturally
extend the existing primitive support responsibility.

Current coupling/problem:
Resolved for scalar numeric primitives: number, integer, non-negative, and
probability checks now live with the extracted type checks.

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
None. Validation branches and exact error maps/messages were moved mechanically.

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
`9d06dd17` (`Extract primitive numeric validation support`).

Next candidate:
Assess enum/equality and list-item primitives as the next cohesive extension.

Blocked:
No.

Notes:
- `schema.ex` decreased from 14,998 to 14,923 lines.
- `PrimitiveValidation` increased from 46 to 132 lines.
- Parent review found no must-fix findings; parent publishing is the active-mode
  fallback because subagent delegation is unavailable.
- The facade remains substantial; this is not a completion claim.
