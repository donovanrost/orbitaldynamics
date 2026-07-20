# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema stable-ID export test family split.

Status:
Selected; implementation pending.

Selected boundary:
Split the 2,182-line stable-ID policy test into three independently runnable
contract families: top-level manifest/package fields, review/import row fields,
and candidate-refresh/contact-allocation/validation fields. Keep all assertions
in the focused stable-ID module.

Selection evidence:
- The row-schema section begins at `operator_review_row_schema` on line 917 and
  needs only freshly loaded Cadence/operator-review schemas plus the stable-ID
  pattern.
- The candidate-refresh section begins at `refresh_schema` on line 1,933 and
  needs only the stable-ID pattern.
- Reinitializing those public schema values makes each family independently
  selectable without duplicating or weakening any assertion.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. The same deterministic fixtures, production calls, assertions,
artifact validation, and async test behavior must remain unchanged.

Last completed slice:
Schema stable-ID JSON-export contract test split, selected in `b94bc5f6` and
implemented in `d271aaa7`. The 3,206-line mixed module became a 1,029-line
general export module and a 2,182-line focused stable-ID policy module.

Next candidate:
Implement and verify the selected stable-ID test-family split.

Blocked:
No.
