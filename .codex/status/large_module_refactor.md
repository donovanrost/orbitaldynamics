# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema stable-ID JSON-export contract test split.

Status:
Completed and verified.

Selected boundary:
Move the 2,177-line stable-ID hint export contract from the 3,206-line JSON
Schema export test into a focused sibling test module. Keep the top-level,
nested-report, opaque-identity, integer-count, and checked-in fixture tests plus
their private helpers in the original module.

Selection evidence:
- The stable-ID test is the first independent test and ends before line 2,183.
- It depends only on the public `Schema` facade and none of the original
  module's private fixture or recursive opaque-property helpers.
- It validates one cohesive policy across standalone artifact identity fields,
  while the remaining tests cover structurally different export contracts.

Implementation:
Selected in `b94bc5f6` and implemented in `d271aaa7`. Moved the exhaustive
stable-ID hint export test into `JsonSchemaStableIdContractsTest`. The original
mixed JSON-export contract module moved from 3,206 to 1,029 lines; the focused
stable-ID policy module is 2,182 lines.

Verification:
- Both JSON-export contract modules passed with warnings as errors: 15 tests.
- The full schema/validation gate passed with warnings as errors: 359 tests.
- Full checked-in schema export regeneration produced no diff.
- Strict forced compile passed with warnings as errors: 4,129 files.
- Touched-file format checks, new-file whitespace checks, and
  `git diff --check` passed.

Behavior/schema changes:
None intended. The same deterministic fixtures, production calls, assertions,
artifact validation, and async test behavior must remain unchanged.

Last completed slice:
Schema stable-ID JSON-export contract test split, selected in `b94bc5f6` and
implemented in `d271aaa7`. The 3,206-line mixed module became a 1,029-line
general export module and a 2,182-line focused stable-ID policy module.

Next candidate:
Inspect the stable-ID contract for cohesive artifact-family sections; otherwise
select a family split from the 2,477-line timeline-summary schema contract
module.

Blocked:
No.
