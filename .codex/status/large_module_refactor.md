# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Campaign-planner station-pressure fixture extraction.

Status:
Completed and verified.

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
Selected in `f5f381e1` and implemented in `d7c16f5c`. Expanded
`ContactAllocationPressureFixtures` with the station-pressure summary builder
and shared pressure-ID helpers. The assertion module moved from 1,803 to 1,743
lines.

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
Campaign-planner station-pressure fixture extraction, selected in `f5f381e1`
and implemented in `d7c16f5c`. The assertion module moved from 1,803 to 1,743
lines.

Next candidate:
Move the remaining capacity-pack fixture family into the established
test-support owner, then reassess the assertion module boundary.

Blocked:
No.
