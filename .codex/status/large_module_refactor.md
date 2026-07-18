# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema export operator-review model/evidence test split.

Status:
Completed and published.

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
- Focused baseline: original export test passed 1 test.
- Strict warnings-as-errors compile passed 3,800 modules.
- Focused operator-review export test passed 1 test.
- Reduced original export test passed 1 test.
- AST conservation proved the four selected assertions and sole helper moved
  exactly; the reduced original is the source AST minus only that boundary.
- Static checks confirmed the original retains 21 operator-review references
  and its other 11 helpers, formatting and diff checks pass, and no temporary
  checker remains.
- Independent review was clean with no correctness or maintainability findings;
  it confirmed the retained 886-expression test is the exact 890-expression
  source minus the four selected expressions.
- The original export test decreased from 8,317 to 8,276 lines; the focused test
  is 65 lines.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Schema export operator-review model/evidence test split, selected in `0e38d868`
and implemented in `6e8d1396`.

Next candidate:
Continue remapping the reduced Timeline facade.

Blocked:
No.
