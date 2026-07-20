# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Campaign-planner capacity-pack fixture extraction.

Status:
Completed and verified.

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
Selected in `4fda4cce` and implemented in `359cb5fb`. Expanded
`ContactAllocationPressureFixtures` with the capacity-pack summary builder and
focused row/contact-ID helpers. The assertion module moved from 1,743 to 1,595
lines and now contains no embedded fixture builders.

Verification:
- The focused strategy contact-allocation pressure suite passed with warnings as
  errors: 7 tests.
- Strict forced compile passed with warnings as errors: 4,129 files.
- Touched-file format checks, new-helper whitespace checks, and
  `git diff --check` passed.
- No production or checked-in schema-export files changed.

Behavior/schema changes:
None intended. The same deterministic fixtures, production calls, assertions,
artifact validation, and async test behavior must remain unchanged.

Last completed slice:
Campaign-planner capacity-pack fixture extraction, selected in `4fda4cce` and
implemented in `359cb5fb`. The assertion module moved from 1,743 to 1,595 lines
and now contains no embedded fixture builders.

Next candidate:
Reassess the remaining CampaignPlanner assertion module and then inspect the
largest OperatorReview test boundary for a coherent family split.

Blocked:
No.
