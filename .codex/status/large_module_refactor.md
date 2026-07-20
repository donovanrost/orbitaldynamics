# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Campaign-planner recommendation-pressure handoff test split.

Status:
Selected; implementation pending.

Selected boundary:
Move the downstream operator-review, Cadence-import, and schema handoff
assertions from the 3,060-line recommendation-pressure assertion test into a
focused sibling test module. Reuse the deterministic scenario fixture from both
tests and keep the recommendation-explanation assertions in the original.

Selection evidence:
- The handoff section begins at `expected_handoff` and depends only on the
  shared scenario artifact.
- It independently verifies exhaustive field propagation through the strategy
  recommendation review row, selected import row, review import, nested source
  row, and both schema validators.
- The original section independently verifies the recommendation explanation
  and risk-pressure mappings.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. The same deterministic fixtures, production calls, assertions,
artifact validation, and async test behavior must remain unchanged.

Last completed slice:
Campaign-planner recommendation-pressure scenario fixture extraction, selected
in `1eee5dbc` and implemented in `c0678ba9`. The assertion module moved from
4,705 to 3,060 lines and the deterministic scenario now has a named fixture
owner.

Next candidate:
Implement and verify the selected handoff test split.

Blocked:
No.
