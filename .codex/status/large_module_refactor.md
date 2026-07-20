# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Planning-analysis branch schema-provider expansion.

Status:
Selected; implementation pending.

Selected boundary:
Move the branch-comparison row/source, score-term row, and branch-scoped
context builders from the public `Schema` facade into the existing
`PlanningAnalysisSchemaProviders` owner. Add the two registry providers and
route the strategy/review-table shared helper captures to public owner
functions.

Selection evidence:
- The public `Schema` facade remains 1,619 lines.
- Branch comparison and score term are planning-analysis registry providers
  already aligned with the existing owner.
- Branch-comparison source rows are shared only by the three review tables;
  branch-scoped context is shared only by strategy explanation and the three
  review property-provider tables.
- The entire cluster depends only on the stable-ID pattern and common schema
  primitives, so no facade callback is required.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. Parent clause heads/order, dispatch-owner calls, provider
laziness, field-hint fallback, stable-ID decoration, public `Schema`, and
checked-in exports must remain unchanged.

Last completed slice:
Contact-planning schema-provider extraction, selected in `a016943e` and
implemented in `2616d693`. The public `Schema` facade moved from 1,629 to 1,619
lines.

Next candidate:
Implement and verify the selected planning-analysis expansion, then re-rank
the remaining public-facade provider clusters.

Blocked:
No.
