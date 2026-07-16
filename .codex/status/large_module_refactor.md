# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Operational-timeline-row callback-bag collapse.

Status:
Complete and published.

Selected slice:
Replace the 21-entry callback bag in `OperationalTimelineRowContracts` with
direct primitive, stable-ID, and collection owners while retaining explicit
precondition, activity-context, integrity-evidence, and timeline-identity
validators.

Why this slice:
Live inventory leaves `schema.ex` at 11,674 lines. The 348-line timeline-row
owner still routes 17 shared validation operations through callback lookup and
has only four genuine Schema composition hooks. This is the next cohesive large
owner cleanup after the readiness, Cadence, and source-evidence slices.

Public facade to preserve:
`OrbitalDynamics.Schema.validate_artifact/2` and every operational timeline row
path, including required/stable identity, lifecycle/approval, station calendar,
dependencies/exclusivity, attitude/integrity fields, exact messages/error order,
timeline/report consumers, and exports.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/operational_timeline_row_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- compile with warnings as errors
- focused readiness/schema/quality-gate replay/operator-review tests
- broader candidate-refresh/operator-review regression
- schema export trio and checked-in export regeneration
- compile-connected xref, format, diff hygiene, and bounded review

Definition of done:
No operational-timeline-row callback bag or lookup/apply trampolines remain;
direct shared owners preserve row validation while the four domain validators
remain explicit boundaries; focused, broader, and export checks pass; and
bounded review finds no blocker.

Outcome:
`schema.ex` fell from 11,674 to 11,650 lines and the timeline-row owner from
348 to 275. The 21-entry callback bag became direct primitive, stable-ID, and
collection validation calls plus four explicit domain-validator arguments. 189
focused, 1,167 broader, and 22 export tests passed; compile, compile-connected
xref, checked-in schema regeneration, format, diff hygiene, and bounded review
were clean.

Verification gaps:
- Full repository suite not run.
- Known baseline: full contact-filter file remains 87/88 due nil-message
  behavior in `SuppressedCandidateContracts`; unrelated to these slices.

Last completed slice:
Operational-timeline-row callback-bag collapse; publication commit pending.

Blocked:
No.
