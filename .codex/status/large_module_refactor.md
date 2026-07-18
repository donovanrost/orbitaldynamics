# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline duplicate-identity annotation extraction.

Status:
Selected; implementation has not started.

Selected boundary:
Move duplicate timeline-identity group detection, row mapping, collision
annotation fields, superseded action preservation, and compact-map cleanup into
a dedicated annotation module. Keep one private Timeline facade used by
operational reports, normalized activity lists, and diff preparation.

Selection evidence:
- The boundary is two adjacent private helpers at Timeline lines 4,908-4,942.
- All three call sites consume the same annotated row list; no public API or
  coordinator contract changes are needed.
- Existing `IdentityGroupingPolicy.rows_by_timeline_id/1` and
  `ArtifactValueEncodingPolicy.compact/1` provide the only dependencies
  directly, so the extraction requires no callbacks.
- The extraction should replace roughly 35 helper lines with one thin facade,
  reducing the current 6,000-line Timeline.
- Timeline integrity annotation, diff-row construction, count summaries,
  operational row construction, and schema logic remain outside the boundary.

Verification:
Pending: focused baseline, implementation, strict compile, focused and full
Timeline tests, schema-contract tests, canonical AST equivalence, static
ownership/facade/public-definition/xref checks, and independent review.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline candidate-rejection derived-reason policy extraction, selected in
`082c5ac9`, implemented in `631d8f84`, and handed off in `5e256d75`.

Next candidate:
Implement and verify this selected boundary before remapping the reduced
Timeline facade.

Blocked:
No.
