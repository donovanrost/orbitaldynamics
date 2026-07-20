# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Campaign artifact JSON-property family extraction.

Status:
Selected; implementation pending.

Selected boundary:
Extract the adjacent campaign-plan and campaign-repair clauses from
`JsonSchemaPropertyRouter` into a campaign artifact family owner. Keep the
parent router's exact clause heads/order and pass its property callback
explicitly so campaign repair preserves recursive timeline-transition schema
routing without coupling the child back to the parent module.

Selection evidence:
- The parent router remains 1,241 lines across 76 contract-family clauses.
- The next two clauses are a contiguous 40-line campaign artifact boundary
  already delegated through one focused dispatcher.
- Campaign repair's only cross-family dependency is its recursive property
  callback for the timeline-transition contract.
- Passing that callback explicitly preserves the recursion and keeps the child
  dependency one-way while reusing `JsonSchemaPropertySupport`.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. Parent clause heads/order, dispatch-owner calls, provider
laziness, field-hint fallback, stable-ID decoration, public `Schema`, and
checked-in exports must remain unchanged.

Last completed slice:
Candidate-refresh JSON-property family extraction, selected in `e7af4d89` and
implemented in `f37766cb`. The parent router moved from 1,264 to 1,241 lines.

Next candidate:
Implement and verify the selected campaign family split, then re-rank the
adjacent realized-state/timeline-report families.

Blocked:
No.
