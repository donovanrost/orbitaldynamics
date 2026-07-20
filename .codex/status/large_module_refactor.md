# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Campaign-planner reservation-conflict pressure fixture extraction.

Status:
Selected; implementation pending.

Selected boundary:
Move the reservation-conflict summary fixture out of the oversized
strategy contact-allocation pressure test and into a named CampaignPlanner
test-support owner. Keep the pressure scenario, production calls, and score-term
assertions in the existing test module.

Selection evidence:
- `strategy_contact_allocation_pressure_test.exs` remains 1,902 lines and still
  owns three independent contact-allocation fixture families plus assertions.
- The reservation-conflict fixture is a self-contained artifact builder used by
  mission-state and prior-plan pressure tests.
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
Campaign-planner provider-reservation pressure fixture extraction, selected in
`9f9e20b4` and implemented in `8e84e3e9`. The assertion module moved from 1,963
to 1,902 lines.

Next candidate:
Implement and verify the selected reservation-conflict fixture extraction.

Blocked:
No.
