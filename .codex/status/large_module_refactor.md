# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Cadence-import comparison-report test-family extraction.

Status:
Implemented, verified, reviewed, and ready to publish.

Selected slice:
Move the adjacent Pareto-frontier and branch/ranking-comparison import tests into
a focused comparison-report module, preserving typed evidence, source-review
handoffs, validation failures, and deterministic row ordering.

Why this slice:
After four splits, the parent is 15,999 lines. Lines 5,036-5,742 form two large,
inline comparison-report tests with no private-helper dependency; the preceding
contact-intent test and following warning/risk test define clean boundaries.

Public facade to preserve:
`OrbitalDynamics.CadenceImport.from_pareto_frontier_report/1`,
`from_branch_comparison_report/1`, `from_ranking_comparison_report/1`,
`OrbitalDynamics.Schema.validate_artifact/1`, exact manifest rows/counts,
typed comparison evidence, validation paths, and deterministic ordering.

Likely files:
- `test/orbital_dynamics/cadence_import_test.exs`
- `test/orbital_dynamics/cadence_import/comparison_report_test.exs`
- `.codex/status/large_module_refactor.md`

Likely verification:
- extracted comparison-report test module directly
- original Cadence import test ledger
- format, diff hygiene, and bounded review

Definition of done:
Both tests move mechanically with assertion strength and edge coverage
unchanged; the original ledger no longer duplicates them, both focused and
original-ledger test files pass, and bounded review finds no blocker.

Outcome:
Exactly two large adjacent comparison-report tests moved byte-for-byte into
`OrbitalDynamics.CadenceImport.ComparisonReportTest`; assertion order, Pareto,
branch/ranking typed evidence, validation failures, and deterministic ordering
are unchanged. The parent fell from 15,999 to 15,292 lines and the focused module
is 713 lines. All 113 Cadence import test names remain unique across the parent
and five extracted modules.

Verification gaps:
- Full repository suite not run; this is a mechanical test-only extraction.

Last completed slice:
Cadence-import comparison-report test-family extraction, publication pending:
the focused module passed 2/2 and the parent passed 96/96; across all six modules
the complete family remains 113/113 with no duplicate names. Format, diff
hygiene, helper-independence checks, and bounded review were clean.

Blocked:
No.
