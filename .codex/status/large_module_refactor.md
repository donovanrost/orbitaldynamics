# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Campaign-planner recommendation-pressure expected-handoff fixture extraction.

Status:
Completed and verified.

Selected boundary:
Move the deterministic expected-handoff contract map from the 2,047-line
recommendation-pressure handoff test into a named test-support fixture owner.
Keep the review/import lookup, field propagation, nested source-row, and schema
assertions in the focused test.

Selection evidence:
- The expected map occupies lines 17-2,008 and is deterministic test data.
- The actual verification flow begins at `recommendation_review_row` and uses
  only the scenario artifact plus that map.
- A dedicated expected-contract fixture keeps exhaustive coverage intact while
  making the focused handoff test navigable.

Implementation:
Selected in `aa9413f4` and implemented in `0315df4a`. Added the 1,998-line
`StrategyRecommendationPressureExpectedHandoffFixture` contract owner and
replaced the embedded map with one fixture call. The focused handoff test moved
from 2,047 to 62 lines while retaining every review/import/schema assertion.

Verification:
- Both focused recommendation-pressure tests passed with warnings as errors:
  2 tests.
- Strict forced compile passed with warnings as errors: 4,129 files.
- Touched-file format checks, new-helper whitespace checks, and
  `git diff --check` passed.
- No production or checked-in schema-export files changed.

Behavior/schema changes:
None intended. The same deterministic fixtures, production calls, assertions,
artifact validation, and async test behavior must remain unchanged.

Last completed slice:
Campaign-planner recommendation-pressure expected-handoff fixture extraction,
selected in `aa9413f4` and implemented in `0315df4a`. The handoff test moved
from 2,047 to 62 lines and its exhaustive contract now has a named fixture
owner.

Next candidate:
Return to the largest schema contract test files and select a coherent
contract-family fixture or test split; the recommendation-pressure tests now
have focused scenario, explanation, expected-contract, and handoff owners.

Blocked:
No.
