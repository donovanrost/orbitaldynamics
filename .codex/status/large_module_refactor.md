# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema export operator-review model/evidence test split.

Status:
Selected; implementation has not started.

Selected boundary:
Move the contiguous four-assertion operator-review block covering its model,
model limits, and missing-numeric-priority evidence fields, together with the
sole `operator_review_package_model_limits/0` helper, into one focused export
test.

Selection evidence:
- The four expressions form one contiguous operator-review model/evidence
  boundary in the bundle-content ledger.
- `operator_review_package_model_limits/0` has no consumer outside the selected
  assertions and can move with the boundary.
- The new test will retain Mix task invocation, captured IO, output cleanup, and
  task re-enablement, so assertions still prove serialized export behavior.
- Other operator-review assertions, the operator/Cadence shared loops and
  matrices, and their local path/lambda dependencies remain in the original
  test; this avoids broadening the slice or weakening cross-family invariants.
- The split should reduce the current 8,317-line bundle-content ledger while
  retaining its other 11 helpers.
- Production code, public APIs, generated schema exports, other contract-family
  assertions, and helper ownership remain outside the boundary.

Verification:
Pending: focused baseline, mechanical assertion/helper move, strict compile,
focused/original test files, structural/static checks, and independent review.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Schema export maneuver-review test split, selected in `322068ce` and implemented
in `8f3cbf6b`.

Next candidate:
Continue remapping the reduced Timeline facade.

Blocked:
No.
