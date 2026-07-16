# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline-transition-application report-count callback collapse.

Status:
Selected; implementation pending.

Selected slice:
Remove the eight-entry callback bag from
`TimelineTransitionApplicationReportCountContracts`. Call primitive validation
and collection aggregation owners directly while preserving the facade wrapper
and report validator boundary.

Why this slice:
Live inventory shows `schema.ex` remains the dominant production hotspot at
12,396 lines. The 219-line count owner contains eight callback trampolines for
count-map validation, derived equality checks, frequency/nested frequency,
numeric sums, list extraction, and stable sorting. Focused transition-report
contracts cover applications, selected activities, all count maps, invalid
values, nested integrity evidence, fixtures, and handoffs.

Public facade to preserve:
`OrbitalDynamics.Schema.validate_artifact/2` and all timeline transition
application report behavior, including application/selection counts,
frequency maps, transition categories, integrity issue sums/types, nil selected
activities, validation order, exact paths/messages, deterministic errors, and
exports.

Likely extraction target:
`TimelineTransitionApplicationReportCountContracts.validate/4` can become
direct-owner `validate/3`. Remove the schema callback factory and owner
trampolines, importing the exact primitive and collection aggregation helpers.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/timeline_transition_application_report_count_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely tests:
- compile with warnings as errors
- focused timeline report and summary contract tests
- transition-application workflow and nested handoff checks
- schema export trio and checked-in export/fingerprint verification
- broader timeline/candidate-refresh checks, xref, format, and diff hygiene

Definition of done:
No report-count callback factory or owner trampolines remain; the facade calls
the direct owner; derived count/map/sum/type behavior stays exact;
focused/broader/export checks pass; and bounded review finds no blocker.

Verification gaps:
- Full repository suite not run.

Last completed slice:
Maneuver-review-report callback collapse published as `1e825f31`: `schema.ex`
fell from 12,420 to 12,396 lines and its owner from 266 to 196; 13 focused, 761
broader, and 22 export tests passed; checked-in schemas were unchanged; bounded
review's must-fix was resolved and re-review found no remaining issues.

Blocked:
No.
