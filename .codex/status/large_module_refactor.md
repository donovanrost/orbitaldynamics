# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
ResourceProjection resource-summary input extraction.

Status:
Selected; implementation pending.

Selected boundary:
Extract external resource-summary key/alias normalization, provenance and
availability normalization, numeric and battery-field derivation, stable
spacecraft identity and value validation, invalid-input row construction, and
duplicate/mixed-scope review gating into
`OrbitalDynamics.ResourceProjection.ResourceSummaryInput`.
Preserve the existing ResourceProjection public API facade.

Selection evidence:
- Live re-ranking places `resource_projection.ex` at 3,447 lines, fourth
  behind Schema, Timeline, and MissionPlan.Activity and ahead of Manifest,
  StationCalendar, ContactAllocation, RecommendationRiskContext,
  TimelineFeedback, OperationalReadiness, ContactContention, and LinkCapacity.
- The selected family owns one intake responsibility used by `report/3`:
  converting untrusted resource-summary inputs into deterministic valid rows or
  review-gated invalid rows before projection math begins.
- Activity input normalization, activity suppression checks, projection and
  roll-forward math, pressure/risk classification, approval policy, flow
  summaries, and artifact assembly remain outside this boundary.
- Existing alias precedence, numeric parsing, derived-margin tolerance,
  wildcard/duplicate scope rules, invalid-row identity, ordering, omission
  behavior, and deterministic output remain unchanged.

Verification:
Pending.

Behavior/schema changes:
None intended. This is a facade-preserving production ownership extraction.

Last completed slice:
TimelineFeedback station-calendar context extraction, selected in `8b6914d7`
and implemented in `a88b7ff5`.
`timeline_feedback.ex` moved from 3,452 to 3,268 lines; the dedicated
station-calendar context owner is 241 lines.

Next candidate:
Re-rank the live largest-module set and select the next cohesive ownership
boundary.

Blocked:
No.
