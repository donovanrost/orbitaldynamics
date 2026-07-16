# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline-publication-handoff callback-bag collapse.

Status:
Complete and published.

Selected slice:
Replace the 3-entry callback bag used by
`TimelineHandoffContracts.validate_timeline_publication_matches_source_summary/4`
with direct primitive validation and one explicit publication-summary validator.

Why this slice:
Live inventory leaves `schema.ex` at 11,650 lines. This 801-line owner has a
single three-entry bag for one public handoff validator: two entries are shared
primitive operations and only publication-summary validation is a genuine
Schema composition boundary.

Public facade to preserve:
`OrbitalDynamics.Schema.validate_artifact/2`, the existing timeline-handoff
public functions, publication-summary source paths, handoff/source equality
messages and issue ordering, report consumers, and exports.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/timeline_handoff_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- compile with warnings as errors
- focused timeline publication/schema/replay/operator-review tests
- broader candidate-refresh/operator-review regression
- schema export trio and checked-in export regeneration
- compile-connected xref, format, diff hygiene, and bounded review

Definition of done:
No timeline-publication-handoff callback bag or local lookup trampolines remain;
shared primitive calls are direct while publication-summary validation remains
an explicit boundary; focused, broader, and export checks pass; and bounded
review finds no blocker.

Outcome:
`schema.ex` fell from 11,650 to 11,641 lines and the timeline-handoff owner
from 801 to 795. The 3-entry bag became two direct primitive calls and one
explicit publication-summary validator. 173 focused, 1,167 broader, and 22
export tests passed; compile, compile-connected xref, checked-in regeneration,
format, diff hygiene, and bounded review were clean.

Verification gaps:
- Full repository suite not run.
- Known baseline: full contact-filter file remains 87/88 due nil-message
  behavior in `SuppressedCandidateContracts`; unrelated to these slices.

Last completed slice:
Timeline-publication-handoff callback-bag collapse; publication commit pending.

Blocked:
No.
