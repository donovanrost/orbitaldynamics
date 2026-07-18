# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema export maneuver-review test split.

Status:
Selected; implementation has not started.

Selected boundary:
Move the dedicated maneuver-review schema assertion block and its sole
model-limit helper into one focused export test. Preserve the
`maneuver_review_report.v1` entry in the shared 11-family policy-decision matrix
in the original test.

Selection evidence:
- The selected expressions cover the maneuver-review model, model limits, and
  row delta-v item type.
- `maneuver_review_report_model_limits/0` has no consumer outside the selected
  assertions and can move with the family.
- The new test will retain Mix task invocation, captured IO, output cleanup, and
  task re-enablement, so assertions still prove serialized export behavior.
- The cross-family policy-decision tuple remains in its existing matrix to avoid
  weakening that shared invariant.
- The split should reduce the current 8,348-line bundle-content ledger while
  retaining its other 12 helpers.
- Production code, public APIs, generated schema exports, other contract-family
  assertions, and helper ownership remain outside the boundary.

Verification:
Pending: focused baseline, mechanical assertion/helper move, strict compile,
focused/original test files, structural/static checks, and independent review.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Schema export timeline-feedback test split, selected in `4e2c27b6` and
implemented in `60ac4dea`.

Next candidate:
Continue remapping the reduced Timeline facade.

Blocked:
No.
