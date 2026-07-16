# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Completed: generic collection validation extraction.

Status:
Published.

Selected slice:
Move row-list, optional-row, numeric-map, and optional-string-list validation
into `Schema.CollectionValidation` behind explicit facade imports.

Why this slice:
These generic container validators share one responsibility, carry no
artifact-family state, and depend only on primitive error construction.

Current coupling/problem:
Resolved for generic row/map containers. Widely reused iteration, type, and
path/error behavior now lives outside the public facade.

Public facade preserved:
- `OrbitalDynamics.Schema.validate_artifact/2`
- `OrbitalDynamics.Schema.validation_report/2`
- All callback arities, ordering, and error maps/messages.

Files changed:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/collection_validation.ex`

Behavior/schema changes:
None. Container iteration, path construction, and error behavior moved exactly.

Tests run:
- `mix compile --warnings-as-errors` passed.
- Broad schema, resource-contract, invalid contact filter/contention ID, and
  schema export coverage passed: 92 tests.
- SHA-256 over `{Schema.contracts(), Schema.json_schema_bundle()}` remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`.
- Xref showed the facade export edge and the sole runtime dependency on
  `PrimitiveValidation`.
- Formatting, whitespace, new-file review, and checked-in-schema cleanliness
  checks passed.

Verification gaps:
- The full suite was not run for this internal extraction.

Last commit:
`4b030cbb` (`Extract generic collection validation support`).

Next candidate:
Assess the adjacent timeline/activity validation adapter cluster for a cohesive
facade-preserving extraction.

Blocked:
No.

Notes:
- `schema.ex` decreased from 14,731 to 14,689 lines.
- `CollectionValidation` is 57 lines.
- Parent review found no must-fix findings; parent publishing is the active-mode
  fallback because subagent delegation is unavailable.
- The facade remains substantial; this is not a completion claim.
