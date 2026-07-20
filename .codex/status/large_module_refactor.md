# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema stable-ID JSON-export contract test split.

Status:
Selected; implementation pending.

Selected boundary:
Move the 2,177-line stable-ID hint export contract from the 3,206-line JSON
Schema export test into a focused sibling test module. Keep the top-level,
nested-report, opaque-identity, integer-count, and checked-in fixture tests plus
their private helpers in the original module.

Selection evidence:
- The stable-ID test is the first independent test and ends before line 2,183.
- It depends only on the public `Schema` facade and none of the original
  module's private fixture or recursive opaque-property helpers.
- It validates one cohesive policy across standalone artifact identity fields,
  while the remaining tests cover structurally different export contracts.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. The same deterministic fixtures, production calls, assertions,
artifact validation, and async test behavior must remain unchanged.

Last completed slice:
Campaign-planner recommendation-pressure expected-handoff fixture extraction,
selected in `aa9413f4` and implemented in `0315df4a`. The handoff test moved
from 2,047 to 62 lines and its exhaustive contract now has a named fixture
owner.

Next candidate:
Implement and verify the selected stable-ID JSON-export contract test split.

Blocked:
No.
