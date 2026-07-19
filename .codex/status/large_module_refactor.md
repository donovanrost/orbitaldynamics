# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
TimelineFeedback operational-feedback grouping extraction.

Status:
Selected; implementation pending.

Selected boundary:
Extract operational-feedback row eligibility, stable grouping-key
normalization, weighted numeric grouping, and deterministic text grouping into
`OrbitalDynamics.TimelineFeedback.FeedbackAggregation`.
Preserve the existing TimelineFeedback public API facade.

Selection evidence:
- Live re-ranking places `timeline_feedback.ex` at 3,675 lines, fourth behind
  Schema, Timeline, and MissionPlan.Activity and ahead of LinkCapacity,
  StationCalendar, Manifest, ResourceProjection, ContactAllocation, and
  RecommendationRiskContext.
- The selected family owns one aggregation-boundary responsibility shared by
  operational-feedback outputs: identity-gated row eligibility and
  deterministic keyed numeric/text reduction.
- Reconciliation, outcome interpretation, downlink demand, target priority,
  resource overrides, uncertainty, provenance, and artifact assembly remain
  outside this boundary.
- Existing exclusion semantics, stable-ID rules, feedback weights, clamping,
  duplicate text selection, key ordering, and empty-map behavior remain
  unchanged.

Verification:
Pending.

Behavior/schema changes:
None intended. This is a facade-preserving production ownership extraction.

Last completed slice:
ResourceProjection margin and warning extraction, selected in `28bb1c49` and
implemented in `24a8fe53`.
`resource_projection.ex` moved from 3,720 to 3,629 lines; the dedicated
margin-projection owner is 170 lines.

Next candidate:
Re-rank the live largest-module set and select the next cohesive ownership
boundary.

Blocked:
No.
