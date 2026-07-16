# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline-diff-row validator callback cleanup.

Status:
Selected; implementation pending.

Selected slice:
Remove the 13-entry callback bag from `TimelineDiffRowContracts`. Call primitive,
stable-ID, activity-context, lifecycle-transition, protection-decision,
timeline-identity, and identity-collision owners directly while preserving the
Schema row wrapper used by report and summary validators.

Why this slice:
Live inventory shows `schema.ex` remains the dominant production hotspot at
12,523 lines. The 151-line row owner contains 13 callback trampolines whose
targets all have extracted owners. One schema wrapper constructs the bag, and
the timeline diff report/summary contract suite covers standalone and nested
row behavior.

Public facade to preserve:
`OrbitalDynamics.Schema.validate_artifact/2` and all timeline diff report/
summary behavior, including required fields, validation order, paths, messages,
optional/wrong-type behavior, identity collision checks, and exports.

Likely extraction target:
`TimelineDiffRowContracts.validate/3` with direct owner calls; remove the schema
row callback factory while keeping `validate_timeline_diff_row/3` as the stable
private routing boundary for existing report and summary callback bags.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/timeline_diff_row_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely tests:
- compile with warnings as errors
- timeline report contracts and focused timeline diff workflow tests
- schema export trio and checked-in export/fingerprint verification
- broader timeline/candidate-refresh checks, xref, format, and diff hygiene

Definition of done:
No row callback factory, callback lookup, or trampolines remain; all direct owner
calls preserve exact behavior; focused/broader/export checks pass; and bounded
review finds no blocker.

Verification gaps:
- Full repository suite not run.

Last completed slice:
Timeline-feedback-report callback collapse published as `44a7bb61`: `schema.ex`
fell from 12,551 to 12,523 lines and its owner from 322 to 234; 80 focused,
73 reviewer-focused, 955 broader, and 22 export tests passed; checked-in schemas
were unchanged; bounded review found no issues.

Blocked:
No.
