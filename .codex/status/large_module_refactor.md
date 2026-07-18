# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema export timeline-feedback test split.

Status:
Selected; implementation has not started.

Selected boundary:
Move all three timeline-feedback schema assertion clusters and their sole
model-limit helper into one focused export test. Preserve end-to-end coverage
by invoking the Mix export task and reading the generated bundle; leave
adjacent realized-activity and candidate assertions in the original test.

Selection evidence:
- The selected expressions cover schema presence, model/limits, row status,
  lighting, orientation, command-authority, and source-context identity fields.
- `timeline_feedback_report_model_limits/0` has no consumer outside the selected
  assertions and can move with the family.
- The new test will retain Mix task invocation, captured IO, output cleanup, and
  task re-enablement, so assertions still prove serialized export behavior.
- The split should further reduce the current 8,450-line bundle-content ledger
  while retaining its other 13 helpers and all non-feedback assertions.
- Production code, public APIs, generated schema exports, other contract-family
  assertions, and helper ownership remain outside the boundary.

Verification:
Pending: focused baseline, mechanical assertion/helper move, strict compile,
focused/original test files, structural/static checks, and independent review.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Schema export operational-timeline test split, selected in `779f8c11` and
implemented in `5b1c6ac9`.

Next candidate:
Continue remapping the reduced Timeline facade.

Blocked:
No.
