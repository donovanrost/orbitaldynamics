# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
RecommendationRiskContext objective-satisfaction projection extraction.

Status:
Selected; implementation pending.

Selected boundary:
Extract objective-satisfaction context keys, risk selection, and context-value
projection into
`OrbitalDynamics.RecommendationRiskContext.ObjectiveSatisfaction`.
Preserve the existing RecommendationRiskContext public API facade.

Selection evidence:
- Live re-ranking places `recommendation_risk_context.ex` at 3,754 lines,
  fourth behind Schema, Timeline, and MissionPlan.Activity and ahead of
  StationCalendar, LinkCapacity, ResourceProjection, TimelineFeedback, and
  Manifest.
- The selected family owns one risk-domain projection responsibility: its
  exported context-key contract, objective-satisfaction risk selection, and
  deterministic aggregation of values from matching risks.
- Score-term, objective-tradeoff, resource-margin, operational-feedback, and
  all other risk projections remain outside this boundary.
- Existing public APIs, atom/string key normalization, list flattening,
  nil/duplicate removal, empty-key omission, and deterministic output remain
  unchanged.

Verification:
Pending.

Behavior/schema changes:
None intended. This is a facade-preserving production ownership extraction.

Last completed slice:
TimelineFeedback outcome-value interpretation extraction, selected in
`886f98ea` and implemented in `67cc2a83`.
`timeline_feedback.ex` moved from 3,776 to 3,675 lines; the dedicated outcome
owner is 204 lines.

Next candidate:
Re-rank the live largest-module set and select the next cohesive ownership
boundary.

Blocked:
No.
