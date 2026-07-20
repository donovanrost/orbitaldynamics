# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Campaign-planner provider-reservation pressure fixture extraction.

Status:
Completed and verified.

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
Selected in `9f9e20b4` and implemented in `8e84e3e9`. Added the 68-line
`ContactAllocationPressureFixtures` test-support owner and imported its
provider-reservation request-summary builder into the existing pressure test.
The assertion module moved from 1,963 to 1,902 lines.

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
Campaign-planner provider-reservation pressure fixture extraction, selected in
`9f9e20b4` and implemented in `8e84e3e9`. The assertion module moved from 1,963
to 1,902 lines.

Next candidate:
Continue moving the remaining independent contact-allocation pressure fixture
families into the new test-support owner, one bounded contract-preserving
fixture family at a time.

Blocked:
No.
