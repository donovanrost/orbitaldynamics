# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Completed: validation-diagnostic callback ownership cleanup.

Status:
Completed and published.

Selected slice:
Replace validation issue and remediation callback plumbing with direct primitive
support calls.

Why this slice:
Both validators use only four operations already owned by primitive support,
and focused schema-validation scoring tests cover their nested rows.

Current coupling/problem:
Resolved. Both diagnostic validators call primitive support directly and the
facade only delegates issue/remediation inputs.

Public facade preserved:
- `OrbitalDynamics.Schema.validate_artifact/2`
- `OrbitalDynamics.Schema.validation_report/2`
- Fixture/report/check order, derived status/counts, comparison errors,
  validation levels, and exact paths/messages.

Files changed:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/validation_diagnostic_contracts.ex`

Definition of done:
Diagnostic callback plumbing is gone, focused issue/remediation/export tests
and fingerprint pass, and xref shows a direct primitive dependency.

Behavior/schema changes:
None. Issue/remediation required fields, severity enum, optional fields,
paths/messages, and deterministic schema output remain unchanged.

Tests run:
- `mix compile --warnings-as-errors` passed.
- Eight validation issue/remediation/scoring and export tests passed.
- Full checked-in schema export produced no diffs.
- Exact schema fingerprint remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`.
- Xref shows the facade caller and direct primitive dependency.
- Formatting and `git diff --check` passed.

Verification gaps:
- Full suite not run; the focused eight-test diagnostic/export gate and
  deterministic fingerprint are the verification boundary for this slice.

Last commit:
`c9ad6ae2` (`Collapse validation diagnostic callbacks`).

Next candidate:
Collapse activity contract callback ownership; its activity/contact validators
use only primitive and stable-ID support, unblocking proposed-contact cleanup.

Blocked:
No.

Notes:
- `schema.ex` is 14,208 lines after this slice (down from 14,219).
- `ValidationDiagnosticContracts` is 31 lines and callback-free.
- Activity-context cleanup was audited and deferred because its 17 callbacks
  include facade-owned validators; this slice is the bounded alternative.
- Parent review/publishing is the active-mode fallback because subagent
  delegation is unavailable.
