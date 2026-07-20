# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Campaign-planner reservation-conflict pressure fixture extraction.

Status:
Completed and verified.

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
Selected in `d3db2b3a` and implemented in `658600c9`. Expanded
`ContactAllocationPressureFixtures` with the reservation-conflict summary
builder and its row/list helpers. The assertion module moved from 1,902 to
1,803 lines.

Verification:
- The focused strategy contact-allocation pressure suite passed with warnings as
  errors: 7 tests.
- Strict forced compile passed with warnings as errors: 4,129 files.
- `git diff --check` passed.
- No production or checked-in schema-export files changed.

Behavior/schema changes:
None intended. The same deterministic fixtures, production calls, assertions,
artifact validation, and async test behavior must remain unchanged.

Last completed slice:
Campaign-planner reservation-conflict pressure fixture extraction, selected in
`d3db2b3a` and implemented in `658600c9`. The assertion module moved from 1,902
to 1,803 lines.

Next candidate:
Continue moving the remaining station-pressure and capacity-pack fixture
families into the established test-support owner.

Blocked:
No.
