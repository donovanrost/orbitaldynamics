# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline candidate-rejection derived-reason policy extraction.

Status:
Selected; implementation has not started.

Selected boundary:
Move the derived candidate-rejection reason pipeline and its two
`maybe_add_reason/3` clauses into a dedicated policy. Have that policy call the
existing station, condition, and boolean policies directly; replace the
coordinator with one private Timeline facade and remove ten now-redundant
station/condition facades. Retain the normalization facade used by the unrelated
activity-precondition callback.

Selection evidence:
- The derived pipeline and two prepend clauses are the single owner of reason
  ordering before the existing final unique/sort step.
- The three station and seven condition private Timeline facades are consumed
  only by that pipeline; their policies already expose equivalent entry points.
- `ActivityBooleanPolicy.first_boolean/2` supplies the remaining payload and
  antenna checks directly, so the new boundary requires no callbacks.
- The extraction should remove the coordinator, two prepend clauses, and ten
  classifier facades while adding one coordinator facade, materially reducing
  the current 6,064-line Timeline.
- Declared reasons, final unique/sort behavior, normalization callback,
  reviewability, report/row construction, and schema logic remain unchanged.

Verification:
Pending: focused baseline, implementation, strict compile, focused and full
Timeline tests, schema-contract tests, canonical AST equivalence, static
ownership/facade/public-definition/xref checks, and independent review.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline candidate-rejection condition policy extraction, initially selected in
`a5fbcc2d`, corrected in `70396748`, implemented in `6e5fc6f3`, and handed off
in `654574f1`.

Next candidate:
Implement and verify this selected boundary before remapping the reduced
Timeline facade.

Blocked:
No.
