# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Completed: validation-reference callback ownership cleanup.

Status:
Completed and published.

Selected slice:
Move generic count-map validation into primitive support and let validation
reference fixture/report/check validation call support directly.

Why this slice:
All twelve callbacks map to support responsibilities once the generic count-map
helper moves; exact fixture/report/check regressions are focused and strong.

Current coupling/problem:
Resolved. Primitive support owns count-map validation, reference contracts call
support directly, and the facade only delegates inputs.

Public facade preserved:
- `OrbitalDynamics.Schema.validate_artifact/2`
- `OrbitalDynamics.Schema.validation_report/2`
- Fixture/report/check order, derived status/counts, comparison errors,
  validation levels, and exact paths/messages.

Files changed:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/primitive_validation.ex`
- `lib/orbital_dynamics/schema/validation_reference_contracts.ex`

Definition of done:
The count-map helper is support-owned, callback plumbing is gone, tests and
fingerprint pass, and xref shows support dependencies.

Behavior/schema changes:
None. Fixture/report/check order, derived status/counts, comparisons, levels,
paths, messages, and deterministic schema output remain unchanged.

Tests run:
- `mix compile --warnings-as-errors` passed.
- Eight validation-evidence, validation-policy, and export tests passed.
- Exact schema fingerprint remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`.
- Xref shows the facade caller and direct primitive support edge.
- Formatting, `git diff --check`, and checked-in schema cleanliness passed.

Verification gaps:
- Full suite not run; the focused eight-test evidence/export gate and
  deterministic fingerprint are the verification boundary for this slice.

Last commit:
`7dac3ee2` (`Collapse validation reference callbacks`).

Next candidate:
Reassess validation-policy ownership; keep mixed activity-context deferred.

Blocked:
No.

Notes:
- `schema.ex` is 14,437 lines after this slice (down from 14,468).
- `ValidationReferenceContracts` is 232 lines and callback-free.
- Activity-context cleanup was audited and deferred because its 17 callbacks
  include facade-owned validators; this slice is the bounded alternative.
- Parent review/publishing is the active-mode fallback because subagent
  delegation is unavailable.
