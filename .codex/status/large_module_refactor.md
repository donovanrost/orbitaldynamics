# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline diff comparison-value policy completion.

Status:
Completed and published.

Selected boundary:
Move the two `diff_compare_value/2` clauses from the Timeline facade into
`DiffFieldSelectionPolicy`, let that policy own comparison across direct and
activity-context fields, and remove the facade callback/helper boundary.

Selection evidence:
- `diff_compare_value/2` is used only as the callback passed to
  `DiffFieldSelectionPolicy.changed_fields/4`; its precedence/fallback logic is
  part of that policy's sole responsibility.
- `@diff_activity_context_compare_fields` remains facade-owned because it is
  still exported through capabilities and included in `@diff_compare_fields`;
  the policy will receive it as configuration.
- Focused timeline-diff tests cover unchanged nested values, changed
  station-calendar evidence, and changed command-feedback evidence.
- The existing policy module is 12 lines and the Timeline facade is 5,329 lines.
- Public Timeline APIs, capability values, report/schema shapes, field ordering,
  generated exports, and other diff responsibilities remain outside the
  boundary.

Verification:
- Focused baseline passed 2 timeline-diff tests.
- Strict warnings-as-errors compile passed 3,800 modules.
- Focused timeline-diff tests passed 2 tests.
- Full Timeline suite passed 127 tests.
- Four Timeline schema-contract suites passed 36 tests.
- AST conservation proved the two comparison branches moved exactly and the
  facade changed only by replacing the callback with the unchanged context-field
  list and removing the two helper clauses.
- Static checks confirmed Timeline has no `diff_compare_value` helper, the policy
  has the sole private comparison function, formatting and diff checks pass, and
  no temporary checker remains.
- Independent review was clean with no correctness or maintainability findings;
  it also confirmed Timeline remains the policy's sole caller and public defs,
  capability fields, report/schema fields, and ordering are unchanged.
- Timeline decreased from 5,329 to 5,319 lines; the policy increased from 12 to
  32 lines.

Behavior/schema changes:
None intended. The facade continues supplying both compare-field lists, so
capabilities and schema exports should remain byte-for-byte stable.

Last completed slice:
Timeline diff comparison-value policy completion, selected in `4b541c00` and
implemented in `76d88290`.

Next candidate:
Continue remapping the reduced Timeline facade after this callback-ownership
seam is closed.

Blocked:
No.
