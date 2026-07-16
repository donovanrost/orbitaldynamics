# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline-transition-application report-count callback collapse.

Status:
Completed; ready to publish.

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

Result:
Removed the eight-entry callback factory and all count-owner trampolines. The
facade now calls `validate/3`; the owner calls primitive validation and
collection aggregation directly and retains exact local facade-compatible
equality-message and list-value behavior. Two now-unused facade aggregation
wrappers were removed. `schema.ex` fell from 12,396 to 12,375 lines and the
count owner from 219 to 176 lines.

Verification:
- compile with warnings as errors passed
- 30 focused report, summary, provenance, workflow, and handoff tests passed
- 882 broader timeline/candidate-refresh tests passed
- 22 schema-export tests passed
- checked-in schema export reproduction produced no diff
- format, diff hygiene, scoped callback residue, and compile-connected xref passed
- bounded read-only review found no issues

Verification gaps:
- Full repository suite not run.

Last completed slice:
Timeline-transition-application report-count callback collapse: `schema.ex`
fell from 12,396 to 12,375 lines and its owner from 219 to 176; 30 focused, 882
broader, and 22 export tests passed; checked-in schemas were unchanged; bounded
review found no issues.

Blocked:
No.
