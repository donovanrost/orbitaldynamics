# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline-feedback-row validator callback cleanup.

Status:
Selected; implementation pending.

Selected slice:
Remove the 21-entry callback bag from `TimelineFeedbackRowContracts`. Call
primitive, stable-ID, activity-context, execution-metric, protection-decision,
and lifecycle-transition owners directly; pass only the existing nested handoff-
field callback bag as explicit data to the four handoff validators.

Why this slice:
Live inventory shows `schema.ex` remains the dominant production hotspot at
12,620 lines. The 301-line row owner eagerly unpacks 21 callbacks before a long
validation pipeline, although 17 targets already have extracted owners. The
same row bag is constructed by direct row validation and by both activity-state
paths; removing it also simplifies the state owner completed in the last slice.

Public facade to preserve:
`OrbitalDynamics.Schema.validate_artifact/2` and all timeline feedback/activity-
state artifact behavior, including required fields, validation order, paths,
messages, optional/wrong-type behavior, nested handoff validation, and exports.

Likely extraction target:
`TimelineFeedbackRowContracts.validate/4` retains arity four but accepts the
nested handoff-field callback list rather than its own mixed callback bag;
`TimelineActivityStateContracts` receives and forwards that same list; remove
the schema row callback factory while keeping the report-level wrapper stable.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/timeline_feedback_row_contracts.ex`
- `lib/orbital_dynamics/schema/timeline_activity_state_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely tests:
- compile with warnings as errors
- dedicated timeline-activity-state and timeline-feedback contract tests
- focused timeline and validation fixture tests
- schema export trio and checked-in export/fingerprint verification
- broader timeline/candidate-refresh checks, xref, format, and diff hygiene

Definition of done:
No row-level callback bag or unpacking remains, all callers supply the same
nested handoff callbacks, direct owners preserve exact behavior, focused/
broader/export checks pass, and bounded review finds no blocker.

Verification gaps:
- Full repository suite not run.

Last completed slice:
Timeline-activity-state callback cleanup published as `86ae8d94`: `schema.ex`
fell from 12,654 to 12,620 lines and its owner from 432 to 330; 13 focused,
20 reviewer-focused, 955 broader, and 22 export tests passed; checked-in schemas
were unchanged; bounded review found no issues.

Blocked:
No.
