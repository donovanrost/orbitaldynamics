# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Campaign-planner station-pressure fixture extraction.

Status:
Selected; implementation pending.

Selected boundary:
Move the station-pressure summary fixture out of the oversized
strategy contact-allocation pressure test and into a named CampaignPlanner
test-support owner. Keep the pressure scenario, production calls, and score-term
assertions in the existing test module.

Selection evidence:
- `strategy_contact_allocation_pressure_test.exs` remains 1,803 lines and still
  owns station-pressure and capacity-pack fixture families plus assertions.
- The station-pressure fixture is a self-contained 60-line artifact builder.
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
Campaign-planner reservation-conflict pressure fixture extraction, selected in
`d3db2b3a` and implemented in `658600c9`. The assertion module moved from 1,902
to 1,803 lines.

Next candidate:
Implement and verify the selected station-pressure fixture extraction.

Blocked:
No.
