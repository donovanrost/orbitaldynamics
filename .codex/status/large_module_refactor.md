# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline-transition-application-row callback-bag collapse.

Status:
Selected; implementation pending.

Selected slice:
Replace the 11-entry callback bag in
`TimelineTransitionApplicationRowContracts` with direct primitive and stable-ID
owners plus five explicit facade-owned nested validators.

Why this slice:
Live inventory shows `schema.ex` remains the dominant production hotspot at
12,257 lines. The 125-line application-row owner has 11 callback trampolines:
six target shared primitive/stable-ID validators, while lifecycle transitions,
protection decisions, identity collisions, selected integrity, and the nested
timeline-diff row remain facade boundaries. Focused transition-application,
replay, review, timeline, and export coverage is available.

Public facade to preserve:
`OrbitalDynamics.Schema.validate_artifact/2` and all transition application-row
behavior, including required/stable fields, decisions and actions, lifecycle and
protection nesting, identity collisions, selected integrity, nested diff rows,
deterministic errors, replay consumers, and exports.

Likely extraction target:
Replace the opaque bag with an explicit signature carrying the five facade-owned
validators, remove shared-helper trampolines, and import the exact primitive and
stable-ID arities directly without changing validator timing.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/timeline_transition_application_row_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely tests:
- compile with warnings as errors
- timeline transition-application and integrity schema contracts
- focused candidate-refresh replay and operator-review consumers
- schema export trio and checked-in export/fingerprint verification
- broader communications/candidate-refresh checks, xref, format, and diff hygiene

Definition of done:
No opaque application-row callback bag or shared-helper trampolines remain;
explicit facade boundaries and direct owners preserve exact validation order and
messages; focused/broader/export checks pass; and bounded review finds no blocker.

Verification gaps:
- Full repository suite not run.

Last completed slice:
Timeline-transition-selected-activity callback collapse published as
`4d6e44ee`: `schema.ex` fell from 12,273 to 12,257 lines and its owner from 144 to 125. The
12-entry bag became direct primitive/stable-ID owners plus two explicit facade
validators; all callback trampolines were removed. 48 focused, 890 broader, and
22 export tests passed; compile, xref, format, diff hygiene, and checked-in
schema regeneration were clean. Bounded review found no issues.

Blocked:
No.
