# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline-diff-report callback-bag collapse.

Status:
Complete; publication pending.

Selected slice:
Remove the 16-entry callback bag from `TimelineDiffReportContracts`. Call
primitive, collection, aggregation, and timeline-diff-row owners directly and
pass only the facade-derived timeline model-limit list as data.

Why this slice:
Live inventory shows `schema.ex` remains the dominant production hotspot at
12,504 lines. The 292-line report owner contains 16 callback trampolines, and
the preceding row cleanup removed its last nested callback dependency. One
schema call site supplies the bag, while focused timeline report tests cover
counts, aggregation, rows, invalid values, and checked-in fixtures.

Public facade to preserve:
`OrbitalDynamics.Schema.validate_artifact/2` and timeline diff report behavior,
including validation order, default/explicit messages, count aggregation,
model-limit comparison, row validation, deterministic errors, and exports.

Likely extraction target:
`TimelineDiffReportContracts.validate/4` retains arity four but accepts the
timeline model-limit list instead of callbacks; remove the schema factory and
owner trampolines, and validate rows through `TimelineDiffRowContracts`.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/timeline_diff_report_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely tests:
- compile with warnings as errors
- timeline report contracts and focused timeline diff fixture/workflow tests
- schema export trio and checked-in export/fingerprint verification
- broader timeline/candidate-refresh checks, xref, format, and diff hygiene

Definition of done:
No report callback factory or trampolines remain; direct owners and model-limit
data preserve exact behavior; focused/broader/export checks pass; and bounded
review finds no blocker.

Result:
Removed the 16-entry report callback factory and all owner trampolines. The
owner now receives only timeline model-limit data and calls extracted primitive,
collection, aggregation, and row validators directly. The now-unused facade
changed-field aggregation wrapper was also removed. `schema.ex` fell from
12,504 to 12,479 lines and the report owner from 292 to 209; public behavior and
exports are unchanged.

Verification:
- compile with warnings as errors passed
- focused timeline-diff contract/fixture matrix: 10 passed, 306 excluded
- reviewer-focused timeline report contracts: 8 passed
- broader timeline and candidate-refresh suites: 882 passed
- schema export trio: 22 passed
- checked-in schema export reproduced with no diff, preserving its fingerprint
- format, diff hygiene, residue, public-definition, and xref checks passed
- bounded read-only review found no must-fix issue

Verification gaps:
- Full repository suite not run.

Last completed slice:
Timeline-diff-row callback cleanup published as `4a7ba164`: `schema.ex` fell
from 12,523 to 12,504 lines and its owner from 151 to 118; 10 focused,
25 reviewer-focused, 882 broader, and 22 export tests passed; checked-in schemas
were unchanged; bounded review found no issues.

Blocked:
No.
