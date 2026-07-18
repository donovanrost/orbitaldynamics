# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline activity delivery-timing policy extraction.

Status:
Selection recorded; implementation has not started.

Selected boundary:
Move collection-end, planned/actual delivery, maximum latency, and
explicit-or-derived planned/actual latency selection into
`Timeline.ActivityDeliveryTimingPolicy`. `Timeline` retains six private entry
points; numeric field selection and delta calculation cross the boundary
explicitly.

Why this slice:
The reduced Timeline facade is 6,364 lines. These six exclusive clauses own the
alias order and explicit/derived precedence that produce collection, delivery,
and latency evidence used by product activity context, operational rows, and
timeline diff review.

Planned proof:
- Focused explicit/derived latency, collection/delivery aliases,
  numeric-string normalization, operational handoff, and latency-diff examples.
- Full Timeline and Timeline schema-contract suites.
- Strict warnings-as-errors compile.
- Canonical AST equivalence for all six moved clauses after normalizing only the
  six facade names and numeric selector/delta callbacks.
- Format, diff, whitespace, ownership, exactly-six-facade, unchanged Timeline
  public-definition, and xref checks.
- Independent read-only review before publication.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline activity thermal-metric policy extraction, selected in `fde9f37a`,
implemented in `dacfb2bd`, and handed off in `b6977bc4`.

Next candidate:
Remap the reduced Timeline facade after this slice, avoiding the wide
activity-to-map coordinator callback surface.

Blocked:
No.
