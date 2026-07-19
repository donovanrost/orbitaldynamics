# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
StationCalendar provider-result canonicalization extraction.

Status:
Selected; implementation pending.

Selected boundary:
Extract the provider-result map-value key contract, recursive value
normalization, and artifact-value canonicalization into
`OrbitalDynamics.Communications.StationCalendar.ProviderResult`.
Preserve the existing StationCalendar public API facade.

Selection evidence:
- Live re-ranking places `station_calendar.ex` at 3,728 lines, fourth behind
  Schema, Timeline, and MissionPlan.Activity and ahead of LinkCapacity,
  ResourceProjection, TimelineFeedback, Manifest, ContactAllocation, and
  RecommendationRiskContext.
- The selected family owns one representation-boundary responsibility used by
  affected-contact and approval-policy rows: deterministic conversion of
  scalar, list, and map-valued provider results into artifact strings.
- Calendar matching, availability precedence, capacity normalization,
  reservations, counteroffers, policy decisions, and artifact assembly remain
  outside this boundary.
- Existing capability metadata, recursive map-key precedence, comma splitting,
  trimming, omission, scalar conversion, and output ordering remain unchanged.

Verification:
Pending.

Behavior/schema changes:
None intended. This is a facade-preserving production ownership extraction.

Last completed slice:
RecommendationRiskContext objective-satisfaction projection extraction,
selected in `6244115e` and implemented in `2814c640`.
`recommendation_risk_context.ex` moved from 3,754 to 3,582 lines; the dedicated
objective-satisfaction owner is 110 lines.

Next candidate:
Re-rank the live largest-module set and select the next cohesive ownership
boundary.

Blocked:
No.
