# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Suppression-handoff callback-bag collapse.

Status:
Complete and published.

Selected slice:
Replace the 6-entry bag shared by suppression duplicate-row and duplicate-group
validation with direct primitive/error ownership and one explicit duplicate-
evidence validator.

Why this slice:
Live inventory leaves `schema.ex` at 11,641 lines. The 293-line suppression
handoff owner routes four shared primitives and its own error construction
through lookup; only duplicate-evidence validation is a genuine Schema
composition boundary.

Public facade to preserve:
`OrbitalDynamics.Schema.validate_artifact/2`, the existing suppression-handoff
public functions, duplicate row/count/index evidence paths, exact messages and
issue ordering, report consumers, and exports.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/suppression_handoff_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- compile with warnings as errors
- focused contact/resource suppression, schema, replay, and operator-review tests
- broader candidate-refresh/operator-review regression
- schema export trio and checked-in export regeneration
- compile-connected xref, format, diff hygiene, and bounded review

Definition of done:
No suppression-handoff callback bag or lookup/apply trampolines remain; direct
shared owners preserve duplicate validation while duplicate evidence remains
an explicit boundary; focused, broader, and export checks pass; and bounded
review finds no blocker.

Outcome:
`schema.ex` fell from 11,641 to 11,627 lines and the suppression-handoff owner
from 293 to 273. The 6-entry bag became direct primitives/local error ownership
and one explicit duplicate-evidence validator. 125 focused, 1,167 broader, and
22 export tests passed; compile, compile-connected xref, checked-in
regeneration, format, diff hygiene, and bounded review were clean.

Verification gaps:
- Full repository suite not run.
- Known baseline: full contact-filter file remains 87/88 due nil-message
  behavior in `SuppressedCandidateContracts`; unrelated to these slices.

Last completed slice:
Suppression-handoff callback-bag collapse; publication commit pending.

Blocked:
No.
