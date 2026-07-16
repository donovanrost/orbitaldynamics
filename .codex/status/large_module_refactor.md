# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Handoff-field validator callback cleanup.

Status:
Selected; implementation pending.

Selected slice:
Remove the six-entry callback bag from `HandoffFieldContracts` by calling
`PrimitiveValidation` and `StableIdValidation` directly. Update its 12 live
invocations and simplify the timeline feedback-row/activity-state boundaries so
they no longer receive or forward nested handoff callbacks.

Why this slice:
Live inventory shows `schema.ex` remains the dominant production hotspot at
12,574 lines. The 279-line handoff owner contains only six primitive callback
trampolines, while all 12 invocations use the same facade factory. The preceding
row/state cleanups expose this bag as their only remaining injected dependency.

Public facade to preserve:
`OrbitalDynamics.Schema.validate_artifact/2` and every artifact using observation
quality, maneuver feedback, link, completion, capacity, eclipse, thermal, or
resource-availability handoff fields, including exact validation order, paths,
messages, optional behavior, and exports.

Likely extraction target:
All `HandoffFieldContracts.validate_*` functions drop the callback argument and
use shared validation owners directly; remove the schema callback factory;
restore `TimelineFeedbackRowContracts.validate/3` and
`TimelineActivityStateContracts.validate/4` as data-only owner boundaries.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/handoff_field_contracts.ex`
- `lib/orbital_dynamics/schema/timeline_feedback_row_contracts.ex`
- `lib/orbital_dynamics/schema/timeline_activity_state_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely tests:
- compile with warnings as errors
- timeline feedback/activity-state and handoff field workflow tests
- focused schema contract and validation fixture tests
- schema export trio and checked-in export/fingerprint verification
- broader timeline/candidate-refresh checks, xref, format, and diff hygiene

Definition of done:
No handoff callback factory or trampolines remain, all 12 invocations use direct
owner arities, row/state owners no longer thread nested callbacks, focused/
broader/export checks pass, and bounded review finds no blocker.

Verification gaps:
- Full repository suite not run.

Last completed slice:
Timeline-feedback-row callback cleanup published as `9c31640d`: `schema.ex`
fell from 12,620 to 12,574 lines; 84 focused, 19 reviewer-focused, 955 broader,
and 22 export tests passed; checked-in schemas were unchanged; bounded review
found no issues.

Blocked:
No.
