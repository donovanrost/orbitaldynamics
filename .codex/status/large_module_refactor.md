# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Campaign-planner recommendation-pressure scenario fixture extraction.

Status:
Selected; implementation pending.

Selected boundary:
Move the deterministic prior-plan and multi-pressure strategy scenario from the
4,705-line recommendation-pressure test into a named CampaignPlanner
test-support fixture owner. Keep every recommendation, handoff, import, and
schema assertion in the existing test module.

Selection evidence:
- The test's scenario construction occupies lines 11-1,660 and produces only
  the `artifact` consumed by the remaining assertions.
- Its 3,000-plus assertion lines independently verify recommendation
  explanations, review/import handoffs, ordering, and schema contracts.
- A fixture owner separates input construction from contract verification
  without splitting or weakening the end-to-end assertion flow.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. The same deterministic fixtures, production calls, assertions,
artifact validation, and async test behavior must remain unchanged.

Last completed slice:
Operator-review embedded contact-allocation summary test split, selected in
`f3835589` and implemented in `b1a21ebf`. The original test moved from 2,385 to
1,126 lines and the independent wrapper-summary family now has its own
1,264-line focused module.

Next candidate:
Implement and verify the selected recommendation-pressure scenario extraction.

Blocked:
No.
