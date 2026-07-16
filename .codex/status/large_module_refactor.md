# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Completed: lifecycle-transition callback ownership cleanup.

Status:
Published.

Selected slice:
Let `Schema.LifecycleTransitionContracts` call `PrimitiveValidation` directly
and remove its facade callback bag and dynamic callback dispatch.

Why this slice:
Both callbacks pointed to primitive support, and the contract module had no
other external callers or facade-specific state.

Current coupling/problem:
Resolved. Lifecycle-transition validation owns its optional type/enum checks and
the facade delegates inputs without constructing callbacks.

Public facade preserved:
- `OrbitalDynamics.Schema.validate_artifact/2`
- `OrbitalDynamics.Schema.validation_report/2`
- Lifecycle-transition validation order and exact errors.

Files changed:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/lifecycle_transition_contracts.ex`

Behavior/schema changes:
None. The same primitive checks execute in the same order.

Tests run:
- `mix compile --warnings-as-errors` passed.
- Direct timeline report plus broad schema/resource/contact/export coverage
  passed: 100 tests.
- SHA-256 over `{Schema.contracts(), Schema.json_schema_bundle()}` remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`.
- Xref showed the expected facade runtime edge and sole dependency on primitive
  support.
- Formatting, whitespace, diff review, and checked-in-schema cleanliness passed.

Verification gaps:
- The full suite was not run for this internal cleanup.

Last commit:
`df4c9320` (`Collapse lifecycle transition callbacks`).

Next candidate:
Assess timeline-identity callback ownership using primitive and stable-ID
support.

Blocked:
No.

Notes:
- `schema.ex` decreased from 14,680 to 14,672 lines.
- `LifecycleTransitionContracts` decreased from 48 to 47 lines while removing
  dynamic callback dispatch.
- Parent review found no must-fix findings; parent publishing is the active-mode
  fallback because subagent delegation is unavailable.
- The facade remains substantial; this is not a completion claim.
