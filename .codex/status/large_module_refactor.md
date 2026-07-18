# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema export maneuver-review test split.

Status:
Completed and published.

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
- Focused baseline: original export test passed 1 test.
- Strict warnings-as-errors compile passed 3,800 modules.
- Focused maneuver-review export test passed 1 test.
- Reduced original export test passed 1 test.
- AST conservation proved the three selected assertions and sole helper moved
  exactly; the reduced original is the source AST minus only that boundary.
- Static checks confirmed the shared maneuver-review policy-decision tuple
  remains, the original retains its other 12 helpers, formatting and diff checks
  pass, and no temporary checker remains.
- Independent review was clean with no correctness or maintainability findings.
- The original export test decreased from 8,348 to 8,317 lines; the focused test
  is 55 lines.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Schema export maneuver-review test split, selected in `322068ce` and implemented
in `8f3cbf6b`.

Next candidate:
Continue splitting a cohesive schema-contract family from the reduced export
bundle test, then return to remapping the reduced Timeline facade.

Blocked:
No.
