# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema stable-ID export test family split.

Status:
Completed and verified.

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
Selected in `3f4d1e2e` and implemented in `d31009c9`. Split the stable-ID policy
module into three tests for top-level manifest/package fields, review/import row
fields, and refresh/allocation/validation fields. All original assertions
remain in place; only public schema/policy values are reloaded at family
boundaries.

Verification:
- The focused stable-ID module passed with warnings as errors: 3 tests.
- The full schema/validation gate passed with warnings as errors: 361 tests.
- Full checked-in schema export regeneration produced no diff.
- Strict forced compile passed with warnings as errors: 4,129 files.
- Touched-file format and `git diff --check` passed.

Behavior/schema changes:
None intended. The same deterministic fixtures, production calls, assertions,
artifact validation, and async test behavior must remain unchanged.

Last completed slice:
Schema stable-ID export test family split, selected in `3f4d1e2e` and
implemented in `d31009c9`. The focused policy module now exposes three
independently runnable contract families instead of one 2,177-line test.

Next candidate:
Select a coherent family split from the 2,477-line timeline-summary schema
contract module, preserving its fixture and assumption helpers.

Blocked:
No.
