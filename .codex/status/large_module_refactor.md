# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline candidate-rejection condition policy extraction.

Status:
Selected; implementation has not started.

Selected boundary:
Move locked-overlap, negative-margin, short-contact, policy-blocked,
stale-state, model-incompatible, and quality-gate-failed classification plus
their token normalization into a dedicated candidate-rejection condition
policy. Keep seven thin private Timeline facades so the derived-reason
coordinator remains unchanged.

Selection evidence:
- The boundary is nine adjacent private clauses at Timeline lines 2,251-2,321,
  consumed only by the derived candidate-rejection reason coordinator.
- Existing field, numeric, timing, lifecycle normalization, and artifact
  encoding policies supply every dependency directly; no callbacks are needed.
- The extraction should replace roughly 71 helper lines with about 21 facade
  lines, materially reducing the current 6,104-line Timeline.
- Station classification, declared reasons, boolean availability checks,
  reviewability, report/row construction, and schema logic remain outside the
  boundary.

Verification:
Pending: focused baseline, implementation, strict compile, focused and full
Timeline tests, schema-contract tests, canonical AST equivalence, static
ownership/facade/public-definition/xref checks, and independent review.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline candidate-rejection station policy extraction, selected in `68aec198`
implemented in `da7ab611`, and handed off in `c34acaa6`.

Next candidate:
Implement and verify this selected boundary before remapping the reduced
Timeline facade.

Blocked:
No.
