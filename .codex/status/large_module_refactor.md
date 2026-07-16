# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Completed: validation-record callback ownership cleanup.

Status:
Completed and published.

Selected slice:
Let validation-record contracts call schema-field, primitive, stable-ID, and
validation-policy support directly.

Why this slice:
All nine callbacks now map to established support owners, with exact focused
validation-record regressions.

Current coupling/problem:
Resolved. Validation records call established support owners directly, and the
facade only delegates standalone/embedded inputs.

Public facade preserved:
- `OrbitalDynamics.Schema.validate_artifact/2`
- `OrbitalDynamics.Schema.validation_report/2`
- Standalone/embedded record order, registered-field checks, tolerance errors,
  validation levels, and exact paths/messages.

Files changed:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/validation_record_contracts.ex`

Definition of done:
The callback bag/wrappers are gone, focused/broad tests and fingerprint pass,
and xref shows only established support dependencies plus Validation registry.

Behavior/schema changes:
None. Standalone/embedded order, registered-field checks, tolerance errors,
levels, paths, messages, and deterministic schema output remain unchanged.

Tests run:
- `mix compile --warnings-as-errors` passed.
- 18 validation-evidence, policy, embedded candidate-refresh, and export tests
  passed.
- Exact schema fingerprint remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`.
- Xref shows primitive/schema-field/Validation registry dependencies; stable-ID
  and policy support are direct source dependencies.
- Formatting, `git diff --check`, and checked-in schema cleanliness passed.

Verification gaps:
- Full suite not run; the focused 18-test record/export gate and deterministic
  fingerprint are the verification boundary for this slice.

Last commit:
`58b6a36d` (`Collapse validation record callbacks`).

Next candidate:
Assess validation-reference policy support; keep mixed activity-context
ownership deferred.

Blocked:
No.

Notes:
- `schema.ex` is 14,468 lines after this slice (down from 14,484).
- `ValidationRecordContracts` is 81 lines and callback-free.
- Activity-context cleanup was audited and deferred because its 17 callbacks
  include facade-owned validators; this slice is the bounded alternative.
- Parent review/publishing is the active-mode fallback because subagent
  delegation is unavailable.
