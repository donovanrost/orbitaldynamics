# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline-activity-precondition validator callback cleanup.

Status:
Complete; publication pending.

Selected slice:
Remove the callback bag from `TimelineActivityPreconditionSummaryContracts` by
calling shared primitive/collection/stable-ID and timeline owners directly,
while passing the facade-derived timeline model-limit list as data.

Why this slice:
Live inventory shows `schema.ex` remains the dominant production hotspot at
12,673 lines with 1,077 private definitions. This 14-entry callback factory and
the owner's callback trampolines duplicate already-extracted validation
ownership. Three facade call sites share the same bag, and focused timeline-
precondition contract/workflow tests cover the behavior.

Public facade to preserve:
`OrbitalDynamics.Schema.validate_artifact/2` and all timeline precondition
artifact behavior, including validation order, paths, messages, model-limit
comparison, and generated schema/export output.

Likely extraction target:
`TimelineActivityPreconditionSummaryContracts.validate/4` retaining arity four
but accepting `timeline_report_model_limits` data instead of callbacks; remove
the schema callback factory and owner callback wrapper functions.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/timeline_activity_precondition_summary_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely tests:
- compile with warnings as errors
- timeline precondition schema-contract and focused workflow tests
- schema export trio and checked-in export/fingerprint verification
- broader timeline/candidate-refresh checks, xref, format, and diff hygiene

Definition of done:
No callback bag or callback trampolines remain for this validator, all three
schema call sites pass the same model-limit list, direct owners preserve exact
behavior, focused/broader/export checks pass, and review finds no blocker.

Result:
Removed the 14-entry schema callback factory and the owner callback trampolines.
All three schema call sites now pass the same facade-derived model-limit list as
data. `schema.ex` fell from 12,673 to 12,654 lines, and the focused owner fell
from 301 to 219 lines without changing the public facade or export output.

Verification:
- compile with warnings as errors passed
- focused timeline-precondition matrix: 38 passed, 306 excluded by locations
- broader timeline and candidate-refresh suites: 882 passed
- schema export trio: 22 passed
- checked-in schema export reproduced with no diff
- schema fingerprint remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`
- format, diff hygiene, and scoped xref checks passed
- bounded read-only review found no must-fix issue; eager model-limit evaluation
  is unobservable because the helper is private, deterministic, and pure

Verification gaps:
- Full repository suite not run.

Last completed slice:
Candidate-rejection context extraction published as `af7de463`: the report-
contract facade's final family-specific private reducer was removed; 24 focused,
755 candidate-refresh, and 22 export tests passed; schemas/fingerprint were
unchanged; bounded review found no issues.

Blocked:
No.
