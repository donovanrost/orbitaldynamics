# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Completed: review-row nested-ID ownership cleanup.

Status:
Completed and published.

Selected slice:
Move generic nested-ID matching into stable-ID support and let review-row link
validation call it directly.

Why this slice:
The one-entry callback routes a stable-identity invariant; four unrelated
callback consumers remain compatible through the facade import.

Current coupling/problem:
Resolved. Stable-ID support owns nested matching, review-row links call it
directly, and the facade only delegates validation inputs.

Public facade preserved:
- `OrbitalDynamics.Schema.validate_artifact/2`
- `OrbitalDynamics.Schema.validation_report/2`
- Review-row source/replacement link order, paths, and exact mismatch errors.

Files changed:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/stable_id_validation.ex`
- `lib/orbital_dynamics/schema/review_row_link_contracts.ex`

Definition of done:
Nested-ID matching is support-owned, the review-row callback bag/wrapper is
gone, exact/broad tests and fingerprint pass, and xref shows stable-ID support.

Behavior/schema changes:
None. Link order, gating, paths, messages, and deterministic schema output
remain unchanged.

Tests run:
- `mix compile --warnings-as-errors` passed.
- 16 operator-review, Cadence-import, resource, export, and three exact nested
  lineage mismatch regressions passed.
- Exact schema fingerprint remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`.
- Xref shows the facade caller and review-row links' sole dependency on
  stable-ID support.
- Formatting, `git diff --check`, and checked-in schema cleanliness passed.

Verification gaps:
- Full suite not run; exact lineage regressions, focused family/export tests,
  and the fingerprint are the verification boundary for this slice.

Last commit:
`09dfca68` (`Collapse review row link callback`).

Next candidate:
Assess resource-projection flow-summary equality ownership; keep mixed
activity-context ownership deferred.

Blocked:
No.

Notes:
- `schema.ex` is 14,523 lines after this slice (down from 14,548).
- Four unrelated nested-ID callback consumers remain compatible through the
  facade import.
- Activity-context cleanup was audited and deferred because its 17 callbacks
  include facade-owned validators; this slice is the bounded alternative.
- Parent review/publishing is the active-mode fallback because subagent
  delegation is unavailable.
