# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Operator-review embedded contact-allocation summary test split.

Status:
Selected; implementation pending.

Selected boundary:
Move the independent embedded contact-allocation summary wrapper test and its
private summary builder from the 2,385-line OperatorReview contact-allocation
test into a focused sibling test module. Keep the other ten adapter/fixture
tests and their two private helpers in the original module.

Selection evidence:
- The embedded-summary test spans lines 1,041-2,289 and is the only consumer of
  `contact_allocation_summary/2`.
- The other ten tests independently cover direct reports, accepted planning
  state, result artifacts, provider reservations, standalone fixtures, and
  source-ID fallback.
- The split gives the wrapper-summary family its own focused invocation without
  weakening its exhaustive field, ordering, or schema assertions.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. The same deterministic fixtures, production calls, assertions,
artifact validation, and async test behavior must remain unchanged.

Last completed slice:
Campaign-planner capacity-pack fixture extraction, selected in `4fda4cce` and
implemented in `359cb5fb`. The assertion module moved from 1,743 to 1,595 lines
and now contains no embedded fixture builders.

Next candidate:
Implement and verify the selected OperatorReview test-family split.

Blocked:
No.
