# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
ResourceProjection flow-summary extraction.

Status:
Completed and pushed in `2e1f6682`.

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
- Strict warning-clean compile passed across 3,947 files:
  `MIX_ENV=test MIX_OS_CONCURRENCY_LOCK=0 mix compile --force --warnings-as-errors`.
- Focused ResourceProjection regression passed: 49 tests.
- Adjacent campaign-planner, candidate-refresh, operator-review, and validation
  ResourceProjection regression bundle passed: 45 tests.
- Exact old/new parity passed 7 comparisons from selection commit `692d755f`
  with `/tmp/resource_projection_flow_summary_compare.exs`, covering live
  report construction, live flow summary/report, rich flow evidence, atom-key
  normalization, and both idempotent summary handoff paths.
- `mix xref callers OrbitalDynamics.ResourceProjection.FlowSummary` reports
  only the ResourceProjection facade.
- The owner has no compile-connected expansion beyond itself.
- Focused formatting, `git diff --check`, removed-helper static checks, and
  final facade/owner review passed.

Behavior/schema changes:
None. The public ResourceProjection facade, report and flow-summary contracts,
deterministic ordering, pressure classification, and error behavior are
unchanged.

Last completed slice:
ResourceProjection flow-summary extraction, selected in `692d755f` and
implemented in `2e1f6682`.
`resource_projection.ex` moved from 3,010 to 2,504 lines; the dedicated
flow-summary owner is 562 lines.

Next candidate:
Re-rank the live largest-module inventory and select the next cohesive,
facade-preserving ownership boundary.

Blocked:
No.
