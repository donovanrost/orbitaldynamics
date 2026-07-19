# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Manifest ground-station catalog input extraction.

Status:
Selected; implementation pending.

Selected boundary:
Extract direct ground-station catalog parsing, candidate-refresh mission-state
fallback, ground-network station normalization, stable-ID dedupe, and
GroundStation construction into
`OrbitalDynamics.Study.Manifest.GroundStationCatalogInput`.
Preserve the existing Manifest public API facade.

Selection evidence:
- Live re-ranking places `study/manifest.ex` at 3,234 lines, fourth behind
  Schema, Timeline, and MissionPlan.Activity and ahead of
  OperationalReadiness, TimelineFeedback, ContactContention, LinkCapacity,
  RecommendationRiskContext, ContactAllocation, ResourceProjection, and
  StationCalendar.
- The selected family is one independent run-input catalog reached once from
  `from_map/1`; it owns source selection, coordinate-bearing station
  normalization, stable-ID dedupe, field validation, and GroundStation
  construction.
- Manifest schema generation, campaign ground-network metadata, candidate
  refresh metadata, target and crossing catalogs, scenario/activity parsing,
  and run assembly remain outside this boundary.
- Existing direct-catalog precedence, empty-list fallback, invalid-field paths,
  coordinate filtering, default minimum elevation, first-ID-wins order,
  constructor behavior, and deterministic output remain unchanged.

Verification:
Pending implementation.

Behavior/schema changes:
None planned. Existing station source precedence and normalization, validation
errors, manifest shape, schema exports, and deterministic output will be
preserved.

Last completed slice:
TimelineFeedback link context extraction, selected in `0816a51b` and
implemented in `2bdd1087`.
`timeline_feedback.ex` moved from 3,268 to 3,153 lines; the dedicated link
context owner is 146 lines.

Next candidate:
Implement and verify the selected ground-station catalog extraction.

Blocked:
No.
