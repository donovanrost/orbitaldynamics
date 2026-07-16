# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline-feedback-report callback-bag collapse.

Status:
Complete; publication pending.

Selected slice:
Remove the 16-entry callback bag from `TimelineFeedbackReportContracts`. Call
primitive, collection, aggregation, operational-feedback, and feedback-row
owners directly; pass the facade-derived model-limit list as data and retain
only the single optional operator-review-package validator function needed for
facade registry routing.

Why this slice:
Live inventory shows `schema.ex` remains the dominant production hotspot at
12,551 lines. The 322-line report owner contains 16 callback trampolines, but
the preceding row and handoff slices eliminated its nested row dependency and
15 targets now have direct owners. One schema call site supplies the bag, and
timeline feedback/state/schema tests already exercise counts and nested rows.

Public facade to preserve:
`OrbitalDynamics.Schema.validate_artifact/2` and timeline feedback report
behavior, including validation order, paths, default and explicit messages,
count derivation, model limits, optional operator-review routing, rows, and
generated schema/export output.

Likely extraction target:
`TimelineFeedbackReportContracts.validate` accepts model-limit data plus a
single optional-package validator instead of a mixed keyword bag; remove the
schema factory and owner trampolines while keeping the facade routing helper.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/timeline_feedback_report_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely tests:
- compile with warnings as errors
- timeline-feedback report/state and validation fixture tests
- schema export trio and checked-in export/fingerprint verification
- broader timeline/candidate-refresh checks, xref, format, and diff hygiene

Definition of done:
No report-level callback bag or trampolines remain, direct owners and explicit
inputs preserve exact behavior, focused/broader/export checks pass, and bounded
review finds no blocker.

Result:
Removed the 16-entry report callback factory and all owner trampolines. The
owner now calls extracted validators, aggregation, operational-feedback, and
feedback-row owners directly; it receives model-limit data plus the single
facade routing function for optional operator-review validation. `schema.ex`
fell from 12,551 to 12,523 lines and the report owner from 322 to 234; public
facade behavior and export output are unchanged.

Verification:
- compile with warnings as errors passed
- focused feedback/operator-review/validation matrix: 80 passed, 181 excluded
- reviewer-focused timeline-feedback suite: 73 passed
- broader timeline, timeline-feedback, and candidate-refresh suites: 955 passed
- schema export trio: 22 passed
- checked-in schema export reproduced with no diff, preserving its fingerprint
- format, diff hygiene, residue, public-definition, and xref checks passed
- bounded read-only review found no must-fix issue

Verification gaps:
- Full repository suite not run.

Last completed slice:
Handoff-field callback cleanup published as `e682160f`: `schema.ex` fell from
12,574 to 12,551 lines and the handoff owner from 279 to 253; 95 focused,
24 reviewer-focused, 955 broader, and 22 export tests passed; checked-in schemas
were unchanged; bounded review found no issues.

Blocked:
No.
