# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Completed: timeline-identity callback ownership cleanup.

Status:
Published.

Selected slice:
Let `Schema.TimelineIdentityContracts` call primitive and stable-ID validation
directly for identity, nested identity, and timeline-link checks.

Why this slice:
Both callbacks pointed to focused support modules, so the identity contract can
own its entire family without facade state or dynamic callback dispatch.

Current coupling/problem:
Resolved. Timeline identity/link validation owns its generic dependencies and
the facade only delegates validation inputs.

Public facade preserved:
- `OrbitalDynamics.Schema.validate_artifact/2`
- `OrbitalDynamics.Schema.validation_report/2`
- Timeline identity/link validation order and exact errors.

Files changed:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/timeline_identity_contracts.ex`

Behavior/schema changes:
None. Stable-ID and optional-type checks execute in the same nested order.

Tests run:
- `mix compile --warnings-as-errors` passed.
- Timeline report/summary plus broad schema/resource/contact/export coverage
  passed: 117 tests.
- SHA-256 over `{Schema.contracts(), Schema.json_schema_bundle()}` remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`.
- Xref showed the expected facade runtime edge and dependencies only on
  primitive and stable-ID support.
- Formatting, whitespace, diff review, and checked-in-schema cleanliness passed.

Verification gaps:
- The full suite was not run for this internal cleanup.

Last commit:
`c90ac848` (`Collapse timeline identity callbacks`).

Next candidate:
Collapse timeline-protection-summary callback ownership using primitive and
stable-ID support.

Blocked:
No.

Notes:
- `schema.ex` decreased from 14,672 to 14,662 lines.
- `TimelineIdentityContracts` decreased from 89 to 84 lines while removing
  dynamic callback dispatch.
- Parent review found no must-fix findings; parent publishing is the active-mode
  fallback because subagent delegation is unavailable.
- The facade remains substantial; this is not a completion claim.
