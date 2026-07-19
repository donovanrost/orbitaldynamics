# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
ResourceProjection margin and warning extraction.

Status:
Selected; implementation pending.

Selected boundary:
Extract starting storage/battery interpretation, storage/downlink/battery
projection math, battery roll-forward, and deterministic projection warnings
into `OrbitalDynamics.ResourceProjection.MarginProjection`.
Preserve the existing ResourceProjection public API facade.

Selection evidence:
- Live re-ranking places `resource_projection.ex` at 3,720 lines, fourth behind
  Schema, Timeline, and MissionPlan.Activity and ahead of TimelineFeedback,
  LinkCapacity, StationCalendar, Manifest, ContactAllocation, and
  RecommendationRiskContext.
- The selected family owns one numerical interpretation responsibility reused
  by aggregate and per-activity projections: initial resource state, bounded
  margins, overflow/shortfall/overuse values, and their ordered warnings.
- Activity normalization, delivery evidence, resource-effect eligibility,
  capacity-source resolution, pressure classification, policy decisions, and
  artifact assembly remain outside this boundary.
- Existing numeric guards, fallback margins, clamping, warning text/order,
  omission behavior, and deterministic output remain unchanged.

Verification:
Pending.

Behavior/schema changes:
None intended. This is a facade-preserving production ownership extraction.

Last completed slice:
LinkCapacity stable contact-identity extraction, selected in `a4818a70` and
implemented in `eef2a62a`.
`link_capacity.ex` moved from 3,724 to 3,656 lines; the dedicated
contact-identity owner is 89 lines.

Next candidate:
Re-rank the live largest-module set and select the next cohesive ownership
boundary.

Blocked:
No.
