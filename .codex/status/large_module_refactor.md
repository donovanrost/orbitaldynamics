# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline-transition-selected-activity callback-bag collapse.

Status:
Selected; implementation pending.

Selected slice:
Replace the 12-entry callback bag in
`TimelineTransitionSelectedActivityContracts` with direct primitive and
stable-ID owners plus explicit facade-owned validators for activity context,
timeline-integrity evidence, interval consistency, and required fields.

Why this slice:
Live inventory shows `schema.ex` remains the dominant production hotspot at
12,273 lines. The 144-line selected-activity owner has 12 callback trampolines:
most target shared primitive/stable-ID validators, while four retain meaningful
facade-owned validation boundaries. Focused transition-application, replay,
review, timeline, and export coverage is available.

Public facade to preserve:
`OrbitalDynamics.Schema.validate_artifact/2` and all transition selected-activity
behavior, including required/stable fields, status enumerations, activity
context, timeline-integrity evidence, interval checks, deterministic errors,
replay consumers, and exports.

Likely extraction target:
Replace the opaque bag with an explicit signature carrying the four facade-owned
validators, remove shared-helper trampolines, and import the exact primitive and
stable-ID arities directly without changing validator timing.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/timeline_transition_selected_activity_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely tests:
- compile with warnings as errors
- timeline transition-application and integrity schema contracts
- focused candidate-refresh replay and operator-review consumers
- schema export trio and checked-in export/fingerprint verification
- broader communications/candidate-refresh checks, xref, format, and diff hygiene

Definition of done:
No opaque selected-activity callback bag or shared-helper trampolines remain;
explicit facade boundaries and direct owners preserve exact validation order and
messages; focused/broader/export checks pass; and bounded review finds no blocker.

Verification gaps:
- Full repository suite not run.

Last completed slice:
Selected-timeline-integrity callback collapse published as `28307a2f`:
`schema.ex` fell
from 12,284 to 12,273 lines and its owner from 260 to 220. The five-entry bag
and all callback trampolines became direct primitive and stable-ID owners. 48
focused, 890 broader, and 22 export tests passed; compile, xref, format, diff
hygiene, and checked-in schema regeneration were clean. Bounded review found no
issues; malformed-input ordering was reviewed structurally rather than through
exhaustive differential generation.

Blocked:
No.
