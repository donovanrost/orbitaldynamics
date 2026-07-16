# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline-transition-application-report callback-bag collapse.

Status:
Selected; implementation pending.

Selected slice:
Replace the 13-entry callback bag in
`TimelineTransitionApplicationReportContracts` with direct primitive and
collection owners plus three explicit facade-owned validators for counts,
selected activities, and application rows.

Why this slice:
Live inventory shows `schema.ex` remains the dominant production hotspot at
12,245 lines. The 168-line application-report owner has 13 callback trampolines:
ten target shared primitive/collection validators, while report counts,
selected-activity rows, and application rows remain facade boundaries. Focused
transition-application, replay, review, timeline, and export coverage is
available.

Public facade to preserve:
`OrbitalDynamics.Schema.validate_artifact/2` and all transition application
report behavior, including contract/model identity, counts and count maps,
model limits, selected activities, application rows, deterministic errors,
replay consumers, and exports.

Likely extraction target:
Replace the opaque bag with an explicit signature carrying the three
facade-owned validators, remove shared-helper trampolines, and import exact
primitive and collection-validation arities without changing validator timing.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/timeline_transition_application_report_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely tests:
- compile with warnings as errors
- timeline transition-application and integrity schema contracts
- focused candidate-refresh replay and operator-review consumers
- schema export trio and checked-in export/fingerprint verification
- broader communications/candidate-refresh checks, xref, format, and diff hygiene

Definition of done:
No opaque application-report callback bag or shared-helper trampolines remain;
explicit facade boundaries and direct owners preserve exact validation order and
messages; focused/broader/export checks pass; and bounded review finds no blocker.

Verification gaps:
- Full repository suite not run.

Last completed slice:
Timeline-transition-application-row callback collapse published as `686b2a32`:
`schema.ex` fell from 12,257 to 12,245 lines while its cohesive owner grew from
125 to 139 to expose five typed facade boundaries. The 11-entry opaque bag and
all callback trampolines were removed; six shared validators now use direct
owners. 48 focused, 890 broader, and 22 export tests passed; compile, xref,
format, diff hygiene, and checked-in schema regeneration were clean. Bounded
review found no issues and judged the explicit dependency tradeoff acceptable.

Blocked:
No.
