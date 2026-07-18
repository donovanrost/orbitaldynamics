# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline diff comparison-value policy completion.

Status:
Selected; implementation has not started.

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
Pending: focused baselines, policy ownership change, strict compile, focused and
full Timeline tests, schema contracts, structural/static checks, and independent
review.

Behavior/schema changes:
None intended. The facade continues supplying both compare-field lists, so
capabilities and schema exports should remain byte-for-byte stable.

Last completed slice:
Schema export operator-review model/evidence test split, selected in `0e38d868`
and implemented in `6e8d1396`.

Next candidate:
Continue remapping the reduced Timeline facade after this callback-ownership
seam is closed.

Blocked:
No.
