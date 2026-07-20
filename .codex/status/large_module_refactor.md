# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Campaign-planner recommendation-pressure expected-handoff fixture extraction.

Status:
Selected; implementation pending.

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
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. The same deterministic fixtures, production calls, assertions,
artifact validation, and async test behavior must remain unchanged.

Last completed slice:
Campaign-planner recommendation-pressure handoff test split, selected in
`b603830b` and implemented in `1844e795`. The 3,060-line assertion module became
a 1,029-line explanation test and a 2,047-line handoff test.

Next candidate:
Implement and verify the selected expected-handoff fixture extraction.

Blocked:
No.
