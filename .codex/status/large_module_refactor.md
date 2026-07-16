# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Completed: activity contract callback ownership cleanup.

Status:
Completed and published.

Selected slice:
Replace shared activity and contact-field callback plumbing with direct
primitive and stable-ID support calls.

Why this slice:
All eight callbacks map to existing support modules; completing this boundary
also makes proposed-contact ownership cleanup direct and bounded.

Current coupling/problem:
Resolved. Shared activity/contact validation calls primitive and stable-ID
support directly, and facade consumers delegate without a callback bag.

Public facade preserved:
- `OrbitalDynamics.Schema.validate_artifact/2`
- `OrbitalDynamics.Schema.validation_report/2`
- Fixture/report/check order, derived status/counts, comparison errors,
  validation levels, and exact paths/messages.

Files changed:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/activity_contracts.ex`

Definition of done:
Activity callback plumbing is gone, focused planned/candidate/contact/export
tests and fingerprint pass, and xref shows direct primitive/stable-ID support.

Behavior/schema changes:
None. Activity/contact required fields, intervals, directions, reservation
metadata, paths/messages, and deterministic schema output remain unchanged.

Tests run:
- `mix compile --warnings-as-errors` passed.
- Seven planned/candidate/contact/campaign/export tests passed.
- Full checked-in schema export produced no diffs.
- Exact schema fingerprint remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`.
- Xref shows the facade caller and direct primitive/stable-ID dependencies.
- Formatting and `git diff --check` passed.

Verification gaps:
- Full suite not run; the focused seven-test activity/export gate and
  deterministic fingerprint are the verification boundary for this slice.

Last commit:
`2f4ffd0e` (`Collapse activity contract callbacks`).

Next candidate:
Collapse proposed-contact callback ownership after activity verification.

Blocked:
No.

Notes:
- `schema.ex` is 14,193 lines after this slice (down from 14,208).
- `ActivityContracts` is 82 lines and callback-free.
- Activity-context cleanup was audited and deferred because its 17 callbacks
  include facade-owned validators; this slice is the bounded alternative.
- Parent review/publishing is the active-mode fallback because subagent
  delegation is unavailable.
