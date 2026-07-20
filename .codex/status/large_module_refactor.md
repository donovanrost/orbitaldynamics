# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema contact-feedback export test split.

Status:
Selected; implementation pending.

Selected boundary:
Move the 940-line nested realized-state/timeline-feedback schema export test
from the 1,853-line contact-feedback contract module into a focused sibling
with its model-limit and JSON fixture helpers. Keep checked-in feedback,
contact-intent, realized-row, and realized-example tests in the original.

Selection evidence:
- The first export test ends before the checked-in timeline-feedback fixture
  test begins at line 946.
- It is the sole consumer of `timeline_feedback_report_model_limits/0` and uses
  only the generic five-line JSON reader otherwise.
- The remaining four tests are behavior/fixture contracts, while the first is
  a cohesive nested-schema export contract.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. The same deterministic fixtures, production calls, assertions,
artifact validation, and async test behavior must remain unchanged.

Last completed slice:
Schema Cadence import handoff test family split, selected in `e9a912b0` and
implemented in `7ff0286b`. The 1,597-line catch-all handoff test now exposes
five independently runnable responsibility families.

Next candidate:
Implement and verify the selected contact-feedback export test split.

Blocked:
No.
