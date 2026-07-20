# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Campaign-planner provider-reservation pressure fixture extraction.

Status:
Selected; implementation pending.

Selected boundary:
Move the provider-reservation request-summary fixture out of the oversized
strategy contact-allocation pressure test and into a named CampaignPlanner
test-support owner. Keep the pressure scenario, production calls, and score-term
assertions in the existing test module.

Selection evidence:
- `strategy_contact_allocation_pressure_test.exs` remains 1,963 lines and owns
  four independent contact-allocation fixture families plus scenario assertions.
- The provider-reservation request fixture is a self-contained 67-line artifact
  builder used by the mission-state summary pressure test.
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
Candidate-refresh source-report provenance fixture extraction, selected in
`920500b6` and implemented in `c084366f`. The assertion module moved from 1,473
to 1,277 lines.

Next candidate:
Implement and verify the selected CampaignPlanner test-fixture extraction.

Blocked:
No.
