# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline-activity-state validator callback cleanup.

Status:
Complete; publication pending.

Selected slice:
Remove the 18-entry callback bag from `TimelineActivityStateContracts`. Call
shared primitive, collection, stable-ID, activity-context, protection-decision,
and lifecycle-transition owners directly; keep state-assumption logic in the
state owner; pass the facade-derived feedback model limits and the existing
nested timeline-feedback-row callback bag as explicit data.

Why this slice:
Live inventory shows `schema.ex` remains the dominant production hotspot at
12,654 lines. The adjacent 432-line state owner contains 18 callback trampolines
to already-extracted validation owners. Its two schema call sites share the same
callback factory, while dedicated activity-state schema tests and timeline
workflow tests cover the contract and nested row behavior.

Public facade to preserve:
`OrbitalDynamics.Schema.validate_artifact/2` and all timeline activity-state
artifact behavior, including validation order, paths, messages, nested feedback
row validation, model-limit comparison, and generated schema/export output.

Likely extraction target:
`TimelineActivityStateContracts.validate` keeps validation ownership and accepts
the feedback model-limit list plus the nested feedback-row callback bag instead
of its own mixed callback bag; remove the schema factory and owner trampolines.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/timeline_activity_state_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely tests:
- compile with warnings as errors
- dedicated timeline-activity-state schema-contract tests
- focused timeline, timeline-feedback, and validation fixture tests
- schema export trio and checked-in export/fingerprint verification
- broader timeline/candidate-refresh checks, xref, format, and diff hygiene

Definition of done:
No state-level callback bag or callback trampolines remain, both schema call
sites pass the same limits and nested-row callbacks, direct owners preserve
exact behavior, focused/broader/export checks pass, and review finds no blocker.

Result:
Removed the 18-entry state callback factory and all owner callback trampolines.
The owner now calls extracted validators directly, owns its assumption check,
and receives only feedback model-limit data plus the unchanged nested-row
callback bag. `schema.ex` fell from 12,654 to 12,620 lines and the state owner
from 432 to 330 lines; the public schema facade and export output are unchanged.

Verification:
- compile with warnings as errors passed
- focused state contract/workflow matrix: 13 passed, 377 excluded by locations
- reviewer-focused state and replay matrix: 20 passed
- broader timeline, timeline-feedback, and candidate-refresh suites: 955 passed
- schema export trio: 22 passed
- checked-in schema export reproduced with no diff, preserving its fingerprint
- format, diff hygiene, removed-caller, public-definition, and xref checks passed
- bounded read-only review found no must-fix issue

Verification gaps:
- Full repository suite not run.

Last completed slice:
Timeline-activity-precondition callback cleanup published as `dd115d41`:
`schema.ex` fell from 12,673 to 12,654 lines and its owner from 301 to 219;
38 focused, 882 broader, and 22 export tests passed; checked-in schemas and the
fingerprint were unchanged; bounded review found no issues.

Blocked:
No.
