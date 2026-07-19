# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
RecommendationRiskContext station-calendar context extraction.

Status:
Completed and pushed.

Selected boundary:
Extract station-calendar risk recognition, the station-calendar context-key
catalog, and station-calendar context projection into
`OrbitalDynamics.RecommendationRiskContext.StationCalendar`.
Preserve the existing RecommendationRiskContext public API facade.

Selection evidence:
- Live re-ranking places `recommendation_risk_context.ex` at 3,293 lines,
  fourth behind Schema, Timeline, and MissionPlan.Activity and ahead of
  TimelineFeedback, Manifest, OperationalReadiness, ContactContention,
  LinkCapacity, ContactAllocation, ResourceProjection, and StationCalendar.
- The selected family is one independent 46-field projection reached through
  `station_calendar_context_keys/0` and `station_calendar_context/1`; it owns
  only station-calendar risk recognition and deterministic context collection.
- Strategy recommendation assembly, Cadence import assembly, schema contracts,
  and every unrelated recommendation-risk context family remain outside this
  boundary.
- Existing atom/string key normalization, type/risk-type/feedback-scope
  recognition, list flattening, first-seen uniqueness, empty-field omission,
  invalid-input fallback, field names, and field order remain unchanged.

Verification:
- Focused baseline before implementation:
  `test/orbital_dynamics/campaign_planner/strategy_recommendation_pressure_events_test.exs`
  passed 1 test.
- Strict compilation after implementation:
  `MIX_ENV=test MIX_OS_CONCURRENCY_LOCK=0 mix compile --force --warnings-as-errors`
  compiled 3,935 files successfully.
- Focused regression:
  `test/orbital_dynamics/campaign_planner/strategy_recommendation_pressure_events_test.exs`
  passed 1 test.
- Adjacent regressions:
  `test/orbital_dynamics/cadence_import/activity_input_test.exs` passed 5 tests
  and
  `test/orbital_dynamics/schema/strategy_recommendation_contracts_test.exs`
  passed 1 test.
- Exact old/new comparison against selection commit `3dbc476a` covered the
  ordered context-key catalog and seven context inputs; all 8 outputs matched
  exactly.
- The exact inputs covered invalid and empty input, irrelevant risks, a
  full-field string-key risk, `risk_type` classification, atom-key
  `feedback_scope` classification, and mixed duplicate values with all three
  accepted station-calendar risk types.
- `git diff --check` passed.
- `mix xref callers
  OrbitalDynamics.RecommendationRiskContext.StationCalendar` reports only the
  RecommendationRiskContext facade as a runtime caller; compile-connected xref
  reports no unexpected coupling.
- Static review confirmed the owner exposes only `context_keys/0` and
  `context/1`; recommendation assembly, Cadence import assembly, schema
  contracts, and unrelated risk families remain outside the boundary.

Behavior/schema changes:
None. Existing risk recognition, key normalization, value flattening,
first-seen uniqueness, omission behavior, field catalog, artifact shape, and
deterministic output are preserved.

Last completed slice:
RecommendationRiskContext station-calendar context extraction, selected in
`3dbc476a` and implemented in `065a1b48`.
`recommendation_risk_context.ex` moved from 3,293 to 3,091 lines; the dedicated
station-calendar context owner is 147 lines.

Next candidate:
Re-rank the live largest-module set and select the next cohesive ownership
boundary.

Blocked:
No.
