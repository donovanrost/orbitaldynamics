# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Completed: stable-ID validation support extraction.

Status:
Published.

Selected slice:
Move the generic stable-ID validation family into
`Schema.StableIdValidation` while retaining the facade's existing local call
and callback shapes through an explicit import.

Why this slice:
The seven related helpers are self-contained around one identity policy and
their own error construction, while serving many artifact-family validators.

Current coupling/problem:
Resolved for stable IDs: collection, nested-map, optional-list, and scalar
checks now live together with the canonical stable-ID pattern.

Public facade preserved:
- `OrbitalDynamics.Schema.identity_policy/0`
- `OrbitalDynamics.Schema.validate_artifact/2`
- `OrbitalDynamics.Schema.validation_report/2`
- All existing contract-specific validation behavior.

Extraction target:
`OrbitalDynamics.Schema.StableIdValidation`.

Files changed:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/stable_id_validation.ex`

Behavior/schema changes:
None. Identity policy, validation error maps/messages, registry contents, and
generated schemas retain the baseline behavior.

Tests run:
- `mix compile --warnings-as-errors` passed.
- Broad schema, resource-contract, invalid contact filter/contention ID, and
  schema export coverage passed: 92 tests.
- SHA-256 over `{Schema.contracts(), Schema.json_schema_bundle()}` remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`.
- Xref showed the expected facade caller and an outbound-dependency-free helper.
- Formatting, whitespace, new-file review, and checked-in-schema cleanliness
  checks passed.

Verification gaps:
- The full suite was not run for this internal extraction.

Last commit:
`4aadbce5` (`Extract stable ID validation support`).

Next candidate:
Assess the adjacent generic scalar/list/type validation primitives as the next
cohesive internal support extraction.

Blocked:
No.

Notes:
- `schema.ex` decreased from 15,096 to 15,034 lines.
- `StableIdValidation` is 84 lines.
- Parent review found no must-fix findings; parent publishing is the active-mode
  fallback because subagent delegation is unavailable.
- The facade remains substantial; this is not a completion claim.
