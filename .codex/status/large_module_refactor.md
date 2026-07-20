# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema timeline change-summary contract test split.

Status:
Selected; implementation pending.

Selected boundary:
Move the publication, dependency-impact, integrity, and diff schema/fixture
tests from the 2,477-line timeline-summary contract module into a focused
timeline change-summary sibling. Keep preservation, transition-application, and
activity-precondition families plus their assumption helpers in the original.

Selection evidence:
- The first eight tests end before the preservation family begins at line
  1,329.
- Those four change-observation families depend only on `Schema` and the
  five-line JSON fixture reader.
- The remaining nine tests form lifecycle preservation/transition/precondition
  contracts and own all three specialized assumption helpers.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. The same deterministic fixtures, production calls, assertions,
artifact validation, and async test behavior must remain unchanged.

Last completed slice:
Schema stable-ID export test family split, selected in `3f4d1e2e` and
implemented in `d31009c9`. The focused policy module now exposes three
independently runnable contract families instead of one 2,177-line test.

Next candidate:
Implement and verify the selected timeline change-summary contract test split.

Blocked:
No.
