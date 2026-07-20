# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema contact-allocation report contract test split.

Status:
Selected; implementation pending.

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
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. The same deterministic fixtures, production calls, assertions,
artifact validation, and async test behavior must remain unchanged.

Last completed slice:
Schema operator-review export test split, selected in `68a5781d` and
implemented in `9041cffc`. The 1,814-line mixed module became a 1,097-line
fixture module and a 728-line nested-export module.

Next candidate:
Implement and verify the selected contact-allocation report contract split.

Blocked:
No.
