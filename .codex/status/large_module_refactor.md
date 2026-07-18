# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline candidate-rejection summary policy extraction.

Status:
Selected; implementation has not started.

Selected boundary:
Move candidate-rejection reason frequencies, predicate-selected candidate IDs,
candidate IDs grouped by rejection reason, candidate IDs grouped by required
operator action, and their deterministic nil-rejecting sort/unique helper into
a dedicated summary policy. Keep the four private Timeline entry points as thin
facades so the report coordinator and public API remain unchanged.

Selection evidence:
- The boundary is four adjacent private helpers at Timeline lines 2,398-2,428
  plus their deterministic `sorted_uniq/1` behavior.
- All four helpers are consumed only by the candidate-rejection report builder
  at Timeline lines 1,342-1,355.
- The extraction should replace roughly 31 helper lines with about 16 facade
  lines, reducing the current 6,179-line Timeline while creating a cohesive
  policy of roughly 40 lines.
- The selected helpers own aggregation and grouping only; row construction,
  reason derivation, station status/capacity interpretation, reviewability,
  report coordination, public definitions, and schema contracts remain in
  Timeline.

Verification:
Pending: focused baseline, implementation, strict compile, focused and full
Timeline tests, schema-contract tests, canonical AST equivalence, static
ownership/facade/public-definition/xref checks, and independent review.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline declared candidate-rejection reason policy extraction, selected in
`c71c6889` and `e59cf630`, implemented in `41dd8346`, and handed off in
`f5f41b36`.

Next candidate:
Implement and verify this selected boundary before remapping the reduced
Timeline facade.

Blocked:
No.
