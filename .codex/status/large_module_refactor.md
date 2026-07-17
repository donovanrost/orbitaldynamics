# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Cadence-import comparison-report test-family extraction.

Status:
Selected; implementation not started.

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
Pending.

Verification gaps:
- Not yet verified.

Last completed slice:
Cadence-import realized-activity test-family extraction published as `76558035`:
four byte-identical tests plus their exact local fixture helper moved into a
196-line focused module, shrinking the parent from 16,183 to 15,999 lines. The
focused module passed 4/4, the parent 98/98, and the full 113-test family remained
unique and green; format, diff hygiene, and bounded review were clean.

Blocked:
No.
