# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Planning-analysis schema-provider extraction.

Status:
Selected; implementation pending.

Selected boundary:
Move the six objective-satisfaction, objective-tradeoff, ranking-row,
ranking-winner, Pareto-row, and constraint-row provider builders from the
public `Schema` facade into a new `PlanningAnalysisSchemaProviders` owner.
Merge its lazy provider map into the existing property context.

Selection evidence:
- The public `Schema` facade remains 1,959 lines after the property-routing
  extraction lane completed.
- These six contiguous, roughly 45-line private builders are referenced only
  by the property provider registry.
- They form a cohesive planning-analysis boundary and depend only on the
  stable-ID pattern plus common JSON-schema primitives.
- A provider-map owner preserves lazy evaluation and removes both registry
  entries and implementation details from the public facade.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. Parent clause heads/order, dispatch-owner calls, provider
laziness, field-hint fallback, stable-ID decoration, public `Schema`, and
checked-in exports must remain unchanged.

Last completed slice:
Candidate-refresh callback-aware JSON-property routing, selected in `c61978d5`
and implemented in `e7dc418b`. The parent router moved from 563 to 552 lines
and now contains only ordered facade routes, the global lighting special case,
fallback, and embedded-contract bridge.

Next candidate:
Implement and verify the selected planning-analysis provider extraction, then
re-rank the remaining public-facade provider clusters.

Blocked:
No.
