# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
ResourceProjection flow-summary extraction.

Status:
Selected; implementation not started.

Selected boundary:
Extract `resource_projection_flow_summary.v1` assembly, projected-remaining
derivation, flow-row flattening, invalid-input routing, pressure routing,
quantity/latency aggregation, and deterministic grouped identities into
`OrbitalDynamics.ResourceProjection.FlowSummary`. Preserve the public
ResourceProjection facade and private delegates for flow/pressure primitives
also used by report construction.

Selection evidence:
- Live re-ranking places `resource_projection.ex` at 3,010 lines,
  fourth behind Schema, Timeline, and MissionPlan.Activity and ahead of
  Manifest, StationCalendar, OrbitalDynamics, RecommendationRiskContext,
  OperationalReadiness, TimelineFeedback, ContactContention, LinkCapacity,
  and ContactAllocation.
- The selected block spans the flow-summary report clause and its cohesive
  helper family from lines 591-1,130. It owns flow counts, ignored and invalid
  routing, resource-pressure dimensions, quantity totals/minima/maxima,
  realized data-volume variance, latency review, projected-resource compaction,
  and stable grouped evidence.
- Report construction also uses flow-row flattening and a subset of pressure
  routing/grouped-ID primitives. Those functions will be exposed by the owner
  and retained behind private facade delegates so there is one implementation.
- Activity/resource-summary normalization, resource projection math,
  approval/risk policy, subsystem capability catalogs, source/trust evidence,
  activity delivery evidence, margin and pressure classification policy,
  report contracts, and public input-shape clauses remain outside this
  boundary.
- Existing row-count derivation, invalid-input fallback, pressure
  classification, stable grouping/sorting, projected-remaining clamping,
  quantity aggregation, latency semantics, model limits, assumptions, schema
  contracts, and deterministic output must remain unchanged.

Verification:
Pending implementation.

Behavior/schema changes:
None intended.

Last completed slice:
LinkCapacity contact-normalization extraction, selected in `7f8dedfb` and
implemented in `053ed894`.
`communications/link_capacity.ex` moved from 3,016 to 2,792 lines; the
dedicated contact-normalization owner is 307 lines.

Next candidate:
Implement and verify the selected ResourceProjection flow-summary extraction.

Blocked:
No.
