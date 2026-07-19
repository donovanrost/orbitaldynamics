# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Manifest ground-network input extraction.

Status:
Selected; implementation pending.

Selected boundary:
Extract campaign/candidate-refresh ground-network list parsing, station
identity aliases, availability/status normalization, interval validation, and
reservation/provider context projection into
`OrbitalDynamics.Study.Manifest.GroundNetworkInput`.
Preserve the existing Manifest public API facade.

Selection evidence:
- Live re-ranking places `study/manifest.ex` at 3,108 lines, fifth behind
  Schema, Timeline, MissionPlan.Activity, and LinkCapacity and ahead of
  ContactAllocation, TimelineFeedback, ContactContention, ResourceProjection,
  StationCalendar, RecommendationRiskContext, and OperationalReadiness.
- Higher-ranked LinkCapacity summary aggregation remains coupled to shared
  station-calendar normalization and reservation inference. The selected
  family is one shared normalization path used by campaign and
  candidate-refresh metadata parsing.
- Manifest schema generation, campaign/candidate-refresh metadata assembly,
  station catalogs, scenarios, activities, resource summaries, and run
  assembly remain outside this boundary.
- Existing list order, invalid-field paths, identity alias precedence,
  availability/status mapping, numeric capacity inference, nullable fields,
  interval rules, omission behavior, and deterministic output remain
  unchanged.

Verification:
Pending implementation.

Behavior/schema changes:
None planned. Existing ground-network normalization, validation errors,
manifest shape, schemas, and deterministic output will be preserved.

Last completed slice:
RecommendationRiskContext activity-lifecycle-state extraction, selected in
`460fb43d` and implemented in `d2fcdfd4`.
`recommendation_risk_context.ex` moved from 3,091 to 2,909 lines; the dedicated
activity-lifecycle-state owner is 220 lines.

Next candidate:
Implement and verify the selected ground-network input extraction.

Blocked:
No.
