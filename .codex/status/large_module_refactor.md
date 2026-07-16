# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Selected-timeline-integrity callback-bag collapse.

Status:
Completed; ready to publish.

Selected slice:
Replace the five-entry callback bag in `TimelineSelectedIntegrityContracts`
with direct primitive and stable-ID owners.

Why this slice:
Live inventory shows `schema.ex` remains the dominant production hotspot at
12,284 lines. The 260-line selected-integrity owner has five uniform callback
trampolines, all targeting existing primitive or stable-ID validators. It is
nested in transition-application rows, with focused transition, integrity,
replay, review, and export coverage available.

Public facade to preserve:
`OrbitalDynamics.Schema.validate_artifact/2` and all selected-timeline-integrity
behavior, including optional field validation, stable-ID lists, allowed issue
types, selected-activity equality messages, deterministic errors, nested
transition rows, replay consumers, and exports.

Likely extraction target:
Replace `validate/4` with `validate/3`, remove the schema bag and owner callback
trampolines, and import the exact primitive and stable-ID arities directly.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/timeline_selected_integrity_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely tests:
- compile with warnings as errors
- timeline transition-application and integrity schema contracts
- focused candidate-refresh replay and operator-review consumers
- schema export trio and checked-in export/fingerprint verification
- broader communications/candidate-refresh checks, xref, format, and diff hygiene

Definition of done:
No selected-integrity callback bag or callback trampolines remain; direct owners
preserve exact validation order/messages; focused/broader/export checks pass;
and bounded review finds no blocker.

Verification gaps:
- Full repository suite not run.

Last completed slice:
Selected-timeline-integrity callback collapse ready to publish: `schema.ex` fell
from 12,284 to 12,273 lines and its owner from 260 to 220. The five-entry bag
and all callback trampolines became direct primitive and stable-ID owners. 48
focused, 890 broader, and 22 export tests passed; compile, xref, format, diff
hygiene, and checked-in schema regeneration were clean. Bounded review found no
issues; malformed-input ordering was reviewed structurally rather than through
exhaustive differential generation.

Blocked:
No.
