# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema contact-allocation report contract test split.

Status:
Completed and verified.

Selected boundary:
Move the three full contact-allocation report regeneration and count-map tests
from the 1,746-line mixed contract module into a focused sibling with the public
`ContactAllocation`/`Schema` aliases and a local JSON reader. Keep the five
standalone summary-family fixture tests and their capability helpers together.

Selection evidence:
- The report-level family begins at line 682 and ends before private helpers.
- Those three tests use only the two public aliases and `read_json!/1`; none of
  the eight summary fixture/capability helpers are referenced.
- The first five tests form a cohesive standalone summary-contract family,
  while the last three exercise full report regeneration and row aggregates.

Implementation:
Selected in `7d687947` and implemented in `bb5bec17`. Moved the three
full-report regeneration/count-map tests into
`ContactAllocationReportContractsTest` with a local JSON reader. The standalone
summary/capability module moved from 1,746 to 982 lines; the full-report module
is 775 lines.

Verification:
- Both contact-allocation schema modules passed with warnings as errors:
  8 tests.
- The full schema/validation gate passed with warnings as errors: 368 tests.
- Full checked-in schema export regeneration produced no diff.
- Strict forced compile passed with warnings as errors: 4,129 files.
- Touched-file format checks, new-file whitespace checks, and
  `git diff --check` passed.

Behavior/schema changes:
None intended. The same deterministic fixtures, production calls, assertions,
artifact validation, and async test behavior must remain unchanged.

Last completed slice:
Schema contact-allocation report contract test split, selected in `7d687947`
and implemented in `bb5bec17`. The 1,746-line mixed module became a 982-line
summary/capability module and a 775-line full-report module.

Next candidate:
Audit the remaining named production facades and test topology against the goal
requirements before selecting another slice or a milestone verification pass.

Blocked:
No.
