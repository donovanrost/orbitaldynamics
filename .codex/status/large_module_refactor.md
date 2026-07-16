# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Completed: priority-override callback ownership cleanup.

Status:
Published.

Selected slice:
Let `Schema.PriorityOverrideContracts` call stable-ID and primitive error support
directly for map, count, and ID-consistency validation.

Why this slice:
Both callbacks pointed to focused support modules, so the complete override
family can own its behavior without facade state or dynamic dispatch.

Current coupling/problem:
Resolved. Override validation owns stable-ID/error dependencies, and the facade
only delegates the map/count/ID-consistency inputs.

Public facade preserved:
- `OrbitalDynamics.Schema.validate_artifact/2`
- `OrbitalDynamics.Schema.validation_report/2`
- Priority override validation order and exact paths/messages.

Files changed:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/priority_override_contracts.ex`

Behavior/schema changes:
None. Override validation ordering and error maps/messages remain exact.

Tests run:
- `mix compile --warnings-as-errors` passed.
- Broad schema/resource/contact/export coverage passed: 92 tests, including
  direct priority count and ID-map mismatch assertions.
- SHA-256 over `{Schema.contracts(), Schema.json_schema_bundle()}` remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`.
- Xref showed the facade runtime edge and dependencies only on primitive and
  stable-ID support.
- Formatting, whitespace, diff review, and checked-in-schema cleanliness passed.

Verification gaps:
- The full suite was not run for this internal cleanup.

Last commit:
`d7f8ec0a` (`Collapse priority override callbacks`).

Next candidate:
Assess execution-metric callback ownership, whose dependencies are primitive
validation only.

Blocked:
No.

Notes:
- `schema.ex` decreased from 14,641 to 14,631 lines.
- `PriorityOverrideContracts` is more explicit at 80 lines while removing all
  dynamic callback dispatch.
- Parent review found no must-fix findings; parent publishing is the active-mode
  fallback because subagent delegation is unavailable.
- The facade remains substantial; this is not a completion claim.
