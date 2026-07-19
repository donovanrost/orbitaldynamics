# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
RecommendationRiskContext activity-lifecycle-state extraction.

Status:
Completed and pushed.

Selected boundary:
Extract timeline-activity lifecycle-state risk recognition, the ordered
context-key catalog, and lifecycle-state context projection into
`OrbitalDynamics.RecommendationRiskContext.TimelineActivityLifecycleState`.
Preserve the existing RecommendationRiskContext public API facade.

Selection evidence:
- Live re-ranking places `recommendation_risk_context.ex` at 3,091 lines,
  seventh behind Schema, Timeline, MissionPlan.Activity, LinkCapacity,
  Manifest, and ContactContention and ahead of ContactAllocation,
  TimelineFeedback, ResourceProjection, StationCalendar, and
  OperationalReadiness.
- Higher-ranked LinkCapacity summary aggregation remains coupled to shared
  station-calendar normalization and reservation inference. The selected
  family is one closed 39-field projection reached through two stable facade
  calls.
- Timeline lifecycle artifact generation, recommendation assembly, Cadence
  import, replay summaries, schemas, and every unrelated risk-context family
  remain outside this boundary.
- Existing atom/string key normalization, type/feedback-scope recognition,
  list flattening, first-seen uniqueness, empty-field omission, invalid-input
  fallback, field order, and deterministic output remain unchanged.

Verification:
- Focused baseline before implementation:
  `test/orbital_dynamics/campaign_planner/strategy_recommendation_pressure_events_test.exs`
  passed 1 test.
- Strict compilation after implementation:
  `MIX_ENV=test MIX_OS_CONCURRENCY_LOCK=0 mix compile --force --warnings-as-errors`
  compiled 3,941 files successfully.
- Focused regression:
  `test/orbital_dynamics/campaign_planner/strategy_recommendation_pressure_events_test.exs`
  passed 1 test.
- Adjacent regressions:
  `test/orbital_dynamics/candidate_refresh/timeline_activity_lifecycle_state_replay_summary_test.exs`
  and
  `test/orbital_dynamics/candidate_refresh/timeline_activity_lifecycle_state_candidate_source_replay_summary_test.exs`
  passed 10 tests together.
- Exact old/new comparison against selection commit `460fb43d` covered the
  ordered 39-key catalog and six context inputs; all 7 outputs matched exactly.
- The exact inputs covered invalid and empty input, irrelevant risks, a
  full-field string-key risk, atom-key feedback-scope classification, both
  accepted classifiers, list flattening, duplicate suppression, and
  first-seen ordering.
- `git diff --check` passed.
- `mix xref callers
  OrbitalDynamics.RecommendationRiskContext.TimelineActivityLifecycleState`
  reports only the RecommendationRiskContext facade as a runtime caller;
  compile-connected xref reports no unexpected coupling.
- Static review confirmed the owner exposes only `context_keys/0` and
  `context/1`; lifecycle artifact generation, recommendation assembly,
  replay/schema logic, and unrelated risk families remain outside the
  boundary.

Behavior/schema changes:
None. Existing lifecycle-state risk recognition and context projection,
recommendation shape, schemas, and deterministic output are preserved.

Last completed slice:
RecommendationRiskContext activity-lifecycle-state extraction, selected in
`460fb43d` and implemented in `d2fcdfd4`.
`recommendation_risk_context.ex` moved from 3,091 to 2,909 lines; the dedicated
activity-lifecycle-state owner is 220 lines.

Next candidate:
Re-rank the live largest-module set and select the next cohesive ownership
boundary.

Blocked:
No.
