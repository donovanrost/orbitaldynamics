# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Completed: timeline-precondition callback ownership cleanup.

Status:
Published.

Selected slice:
Let `Schema.TimelinePreconditionContracts` call `PrimitiveValidation` directly
and remove its facade-owned callback bag and dynamic callback dispatch.

Why this slice:
All three callbacks pointed to primitive support, so the contract module can own
its complete validation behavior without facade state.

Current coupling/problem:
Resolved. Timeline-precondition validation owns its primitive dependencies and
the facade only delegates validation inputs.

Public facade preserved:
- `OrbitalDynamics.Schema.validate_artifact/2`
- `OrbitalDynamics.Schema.validation_report/2`
- Timeline-precondition validation order and exact errors.

Files changed:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/timeline_precondition_contracts.ex`

Behavior/schema changes:
None. The same enum/type/error operations execute in the same order.

Tests run:
- `mix compile --warnings-as-errors` passed.
- Broad schema/resource/contact/export coverage passed: 101 tests.
- Direct timeline report/summary contract coverage passed: 25 tests, including
  the invalid precondition field path/message assertion.
- SHA-256 over `{Schema.contracts(), Schema.json_schema_bundle()}` remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`.
- Xref showed the expected facade runtime edge and dependencies only on
  primitive support and timeline capabilities.
- Formatting, whitespace, diff review, and checked-in-schema cleanliness passed.

Verification gaps:
- The full suite was not run for this internal cleanup.

Last commit:
`951df0c7` (`Collapse timeline precondition callbacks`).

Next candidate:
Collapse the lifecycle-transition primitive-only callback bag using the same
contract-owned dependency pattern.

Blocked:
No.

Notes:
- `schema.ex` decreased from 14,689 to 14,680 lines.
- `TimelinePreconditionContracts` decreased from 63 to 41 lines.
- Parent review found no must-fix findings; parent publishing is the active-mode
  fallback because subagent delegation is unavailable.
- The facade remains substantial; this is not a completion claim.
