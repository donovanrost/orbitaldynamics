# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
TimelineFeedback link context extraction.

Status:
Completed and pushed.

Selected boundary:
Extract link protocol, RF configuration, data rate, link-quality measurements,
lock flags, and link-quality status projection into
`OrbitalDynamics.TimelineFeedback.LinkContext`.
Preserve the existing TimelineFeedback public API facade.

Selection evidence:
- Live re-ranking places `timeline_feedback.ex` at 3,268 lines, fourth behind
  Schema, Timeline, and MissionPlan.Activity and ahead of Manifest,
  OperationalReadiness, ContactContention, LinkCapacity,
  RecommendationRiskContext, ContactAllocation, ResourceProjection, and
  StationCalendar.
- The selected family is one independent 15-field projection merged into both
  planned and realized feedback rows; it owns link-value path precedence and
  artifact normalization but not reconciliation or feedback aggregation.
- Throughput derivation remains owned by the existing
  `TimelineFeedback.Throughput` module. Planned/realized row assembly, station
  calendar, resource, pointing, attitude, command-authority, lighting,
  observation-quality, and thermal contexts remain outside this boundary.
- Existing top-level/nested/metadata path precedence, atom/string scalar
  normalization, numeric and boolean parsing, omission behavior, row shape,
  and deterministic output remain unchanged.

Verification:
- Focused baseline before implementation:
  `test/orbital_dynamics/timeline_feedback_test.exs` passed 73 tests.
- Strict compilation after implementation:
  `MIX_ENV=test MIX_OS_CONCURRENCY_LOCK=0 mix compile --force --warnings-as-errors`
  compiled 3,936 files successfully.
- Focused regression:
  `test/orbital_dynamics/timeline_feedback_test.exs` passed 73 tests.
- Adjacent regressions:
  `test/orbital_dynamics/operator_review/timeline_feedback_test.exs` passed
  2 tests,
  `test/orbital_dynamics/candidate_refresh/operational_timeline_feedback_build_test.exs`
  passed 2 tests, and
  `test/orbital_dynamics/campaign_planner/strategy_timeline_feedback_source_report_test.exs`
  passed 1 test.
- Exact old/new comparison against selection commit `0816a51b` covered seven
  normalized realized rows and four full reconciliation reports; all 11
  outputs matched exactly.
- The exact inputs covered empty context, full top-level values, fallback
  aliases, nested values, metadata fallbacks, conflicting precedence, numeric
  and boolean coercion, and invalid values.
- `git diff --check` passed.
- `mix xref callers OrbitalDynamics.TimelineFeedback.LinkContext` reports only
  the TimelineFeedback facade as a runtime caller; compile-connected xref
  reports no unexpected coupling.
- Static review confirmed the owner exposes only `build/1`; reconciliation,
  feedback aggregation, throughput derivation, and every other activity
  context remain outside the boundary.

Behavior/schema changes:
None. Existing link-value precedence and normalization, omission behavior,
feedback-row shape, artifact contracts, and deterministic output are
preserved.

Last completed slice:
TimelineFeedback link context extraction, selected in `0816a51b` and
implemented in `2bdd1087`.
`timeline_feedback.ex` moved from 3,268 to 3,153 lines; the dedicated link
context owner is 146 lines.

Next candidate:
Re-rank the live largest-module set and select the next cohesive ownership
boundary.

Blocked:
No.
