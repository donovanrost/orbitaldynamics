# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Handoff-field validator callback cleanup.

Status:
Complete; publication pending.

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

Result:
Removed the six-entry handoff callback factory and all owner trampolines. All 15
handoff validators now call primitive/stable-ID owners directly, all 12 external
invocations use the reduced arities, and the feedback row/state boundaries no
longer thread nested callbacks. `schema.ex` fell from 12,574 to 12,551 lines and
the handoff owner from 279 to 253; public facade behavior is unchanged.

Verification:
- compile with warnings as errors passed
- focused handoff/timeline/schema matrix: 95 passed, 180 excluded
- reviewer-focused handoff/timeline-state matrix: 24 passed
- broader timeline, timeline-feedback, and candidate-refresh suites: 955 passed
- schema export trio: 22 passed
- checked-in schema export reproduced with no diff, preserving its fingerprint
- format, diff hygiene, residue, arity-sensitive callsite, public-definition,
  and xref checks passed
- bounded read-only review found no must-fix issue

Verification gaps:
- Full repository suite not run.

Last completed slice:
Timeline-feedback-row callback cleanup published as `9c31640d`: `schema.ex`
fell from 12,620 to 12,574 lines; 84 focused, 19 reviewer-focused, 955 broader,
and 22 export tests passed; checked-in schemas were unchanged; bounded review
found no issues.

Blocked:
No.
