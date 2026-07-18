# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline candidate-rejection station policy extraction.

Status:
Selected; implementation has not started.

Selected boundary:
Move station unavailable, reservation, and reduced-capacity classification;
top-level/source status lookup; top-level/source capacity-fraction lookup; and
the three capacity field names into a dedicated candidate-rejection station
policy. Keep three thin private Timeline facades for the derived-reason
coordinator and expose the field list back to Timeline's existing capability
metadata.

Selection evidence:
- The boundary is 11 adjacent private clauses at Timeline lines 2,243-2,315,
  consumed only by the three derived candidate-rejection reason checks.
- The policy can reuse `ActivityFieldValuePolicy` and
  `ActivityNumericValuePolicy` directly, avoiding coordinator callbacks.
- Timeline's capacity path metadata remains unchanged and can derive its field
  list from the policy's single source of truth at compile time.
- The extraction should replace roughly 73 helper lines with three thin
  facades, materially reducing the current 6,170-line Timeline.
- Locked-overlap, margin, duration, policy, freshness, compatibility, quality,
  declared-reason, report, row, and schema logic remain outside the boundary.

Verification:
Pending: focused baseline, implementation, strict compile, focused and full
Timeline tests, schema-contract tests, canonical AST equivalence, static
ownership/facade/public-definition/xref checks, and independent review.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline candidate-rejection summary policy extraction, selected in `5449e522`
implemented in `63a5d72c`, and handed off in `886c86c9`.

Next candidate:
Implement and verify this selected boundary before remapping the reduced
Timeline facade.

Blocked:
No.
