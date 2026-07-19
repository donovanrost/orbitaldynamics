# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
RecommendationRiskContext station-reservation-hold import-readiness extraction.

Status:
Selected; implementation not started.

Selected boundary:
Extract the station-reservation-hold import-readiness context-key catalog,
risk selection, key/value routing, nested summary preservation, deterministic
normalization, and empty-context behavior into
`OrbitalDynamics.RecommendationRiskContext.StationReservationHoldImportReadiness`.
Preserve the public RecommendationRiskContext facade with delegates for the key
catalog and context builder.

Selection evidence:
- Live re-ranking places `recommendation_risk_context.ex` at 2,909 lines,
  fifth behind Schema, Timeline, MissionPlan.Activity, and the intentionally
  public `OrbitalDynamics` facade, and ahead of OperationalReadiness,
  TimelineFeedback, ContactContention, LinkCapacity, StationCalendar, and
  ResourceProjection.
- The selected responsibility owns a 27-key catalog at lines 136-164 and the
  context collector at lines 1,167-1,303. It selects risks carrying hold import
  status/readiness/summary evidence and routes status, source, artifact type,
  classification, hold and contact IDs, nested direction/station maps, count
  maps, execution boundaries, write/acceptance boundaries, provenance, and the
  preserved source summary.
- The root `OrbitalDynamics` file remains unchanged because its size is
  dominated by intentional public facade clauses rather than private
  implementation ownership.
- All other recommendation risk contexts and their catalogs, recommendation
  construction, campaign strategy, policy evaluation, and source artifact
  generation remain outside this boundary.
- Existing atom/string normalization, list flattening, deterministic
  `term_to_binary` ordering, duplicate removal, omission of empty keys, nested
  map preservation, and non-list fallback must remain unchanged.

Verification:
Pending implementation.

Behavior/schema changes:
None intended.

Last completed slice:
StationCalendar provider-counteroffer handoff-summary extraction, selected in
`4dcb6468` and implemented in `bb5307a5`.
`communications/station_calendar.ex` moved from 2,981 to 2,778 lines; the
dedicated handoff-summary owner is 265 lines.

Next candidate:
Implement and verify the selected RecommendationRiskContext
station-reservation-hold import-readiness extraction.

Blocked:
No.
