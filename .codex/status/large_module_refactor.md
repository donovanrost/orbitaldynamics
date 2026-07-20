# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Campaign-planner capacity-pack fixture extraction.

Status:
Selected; implementation pending.

Selected boundary:
Move the capacity-pack summary fixture out of the oversized
strategy contact-allocation pressure test and into a named CampaignPlanner
test-support owner. Keep the pressure scenario, production calls, and score-term
assertions in the existing test module.

Selection evidence:
- `strategy_contact_allocation_pressure_test.exs` remains 1,743 lines and its
  final embedded fixture family is the capacity-pack artifact builder.
- Its artifact construction belongs with CampaignPlanner test-support fixtures,
  while the consuming test should retain the pressure-routing assertions.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. The same deterministic fixtures, production calls, assertions,
artifact validation, and async test behavior must remain unchanged.

Last completed slice:
Campaign-planner station-pressure fixture extraction, selected in `f5f381e1`
and implemented in `d7c16f5c`. The assertion module moved from 1,803 to 1,743
lines.

Next candidate:
Implement and verify the selected capacity-pack fixture extraction.

Blocked:
No.
