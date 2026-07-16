# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Completed: timeline-protection-summary callback ownership cleanup.

Status:
Published.

Selected slice:
Move generic `expect_field_at_least/5` into primitive support, then let
`Schema.TimelineProtectionSummaryContracts` call primitive and stable-ID support
directly without facade callbacks.

Why this slice:
The minimum-bound helper was the only callback not already support-owned; moving
it completed a cohesive summary-validation dependency boundary.

Current coupling/problem:
Resolved. Protection-summary validation owns its focused dependencies, and the
generic minimum-bound helper is reusable from primitive support.

Public facade preserved:
- `OrbitalDynamics.Schema.validate_artifact/2`
- `OrbitalDynamics.Schema.validation_report/2`
- Protection-summary validation ordering and exact errors.

Files changed:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/primitive_validation.ex`
- `lib/orbital_dynamics/schema/timeline_protection_summary_contracts.ex`

Behavior/schema changes:
None. Count bounds and stable-ID list checks execute in the same order.

Tests run:
- `mix compile --warnings-as-errors` passed.
- Timeline report/summary, repair-protection, and broad schema/resource/contact/
  export coverage passed: 125 tests.
- SHA-256 over `{Schema.contracts(), Schema.json_schema_bundle()}` remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`.
- Xref showed the facade runtime edge and dependencies only on primitive and
  stable-ID support.
- Formatting, whitespace, diff review, and checked-in-schema cleanliness passed.

Verification gaps:
- The full suite was not run for this internal cleanup.

Last commit:
`38866e75` (`Collapse timeline protection summary callbacks`).

Next candidate:
Assess priority-override callback ownership, whose remaining dependencies are
stable-ID validation and primitive error construction.

Blocked:
No.

Notes:
- `schema.ex` decreased from 14,662 to 14,641 lines.
- `TimelineProtectionSummaryContracts` decreased from 80 to 49 lines.
- `PrimitiveValidation` increased from 307 to 319 lines.
- Parent review found no must-fix findings; parent publishing is the active-mode
  fallback because subagent delegation is unavailable.
- The facade remains substantial; this is not a completion claim.
