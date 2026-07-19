# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
RecommendationRiskContext station-reservation-hold import-readiness extraction.

Status:
Completed and pushed in `04980e12`.

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
- Existing top-level atom/string normalization, list flattening, first-seen
  ordering, duplicate removal, omission of empty keys, nested map preservation,
  and non-list fallback must remain unchanged.

Verification:
- Strict warning-clean compile passed across 3,950 files:
  `MIX_ENV=test MIX_OS_CONCURRENCY_LOCK=0 mix compile --force --warnings-as-errors`.
- Focused recommendation-pressure context assertion passed: 1 test.
- Adjacent recommendation-pressure, station-reservation recommendation, and
  Cadence provider-reservation handoff regression bundle passed: 5 tests.
- Exact old/new parity passed 7 comparisons from selection commit `4501d5fe`
  with `/tmp/reservation_hold_risk_context_compare.exs`, covering the 27-key
  catalog, full string-key and top-level atom-key contexts, nested maps,
  first-seen ordering and duplicate removal, irrelevant risks, and nil/map
  fallbacks.
- `mix xref callers
  OrbitalDynamics.RecommendationRiskContext.StationReservationHoldImportReadiness`
  reports only the RecommendationRiskContext facade.
- The owner has no compile-connected expansion beyond itself.
- Focused formatting, `git diff --check`, removed-owner static checks, and
  final facade/owner review passed.

Behavior/schema changes:
None. The public RecommendationRiskContext facade, 27-key catalog, top-level
normalization, first-seen ordering, nested map preservation, empty-key
omission, and fallback behavior are unchanged.

Last completed slice:
RecommendationRiskContext station-reservation-hold import-readiness
extraction, selected in `4501d5fe` and implemented in `04980e12`.
`recommendation_risk_context.ex` moved from 2,909 to 2,748 lines; the dedicated
context owner is 202 lines.

Next candidate:
Re-rank the live largest-module inventory and select the next cohesive,
facade-preserving ownership boundary.

Blocked:
No.
