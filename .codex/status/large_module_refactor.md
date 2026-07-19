# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
TimelineFeedback thermal context extraction.

Status:
Completed and pushed.

Selected boundary:
Extract declared/planned/actual temperature selection, operating-limit
selection, explicit/derived thermal margin, and thermal evidence projection
into `OrbitalDynamics.TimelineFeedback.ThermalContext`.
Preserve the existing TimelineFeedback public API facade.

Selection evidence:
- Live re-ranking places `timeline_feedback.ex` at 3,153 lines, fourth behind
  Schema, Timeline, and MissionPlan.Activity and ahead of ContactContention,
  LinkCapacity, Manifest, RecommendationRiskContext, ContactAllocation,
  ResourceProjection, StationCalendar, and OperationalReadiness.
- The selected family is one independent 12-field projection merged into both
  planned and realized feedback rows; it owns temperature alias precedence and
  thermal-margin derivation but not reconciliation or resource aggregation.
- Shared numeric parsing, stable identifier handling, and artifact omission
  remain owned by existing TimelineFeedback helper modules. Planned/realized
  row assembly and every other activity context remain outside this boundary.
- Existing explicit-value precedence, actual/planned/declared fallback,
  one-sided and two-sided derived-margin formulas, atom/string normalization,
  omission behavior, row shape, and deterministic output remain unchanged.

Verification:
- Focused baseline before implementation:
  `test/orbital_dynamics/timeline_feedback_test.exs` passed 73 tests.
- Strict compilation after implementation:
  `MIX_ENV=test MIX_OS_CONCURRENCY_LOCK=0 mix compile --force --warnings-as-errors`
  compiled 3,939 files successfully.
- Focused regression:
  `test/orbital_dynamics/timeline_feedback_test.exs` passed 73 tests.
- Adjacent regressions:
  `test/orbital_dynamics/operator_review/timeline_feedback_test.exs` passed
  2 tests,
  `test/orbital_dynamics/candidate_refresh/operational_timeline_feedback_build_test.exs`
  passed 2 tests, and
  `test/orbital_dynamics/campaign_planner/strategy_timeline_feedback_source_report_test.exs`
  passed 1 test.
- Exact old/new comparison against selection commit `4ccc5828` covered seven
  normalized realized rows and four full reconciliation reports; all 11
  outputs matched exactly.
- The exact inputs covered empty context, full direct values, aliases,
  two-sided and one-sided derived margins, explicit-margin precedence,
  planned/actual deltas, scalar normalization, invalid identifiers, and
  invalid numeric values.
- `git diff --check` passed.
- `mix xref callers OrbitalDynamics.TimelineFeedback.ThermalContext` reports
  only the TimelineFeedback facade as a runtime caller; compile-connected xref
  reports no unexpected coupling.
- Static review confirmed the owner exposes only `build/1`; reconciliation,
  row assembly, resource aggregation, and every other activity context remain
  outside the boundary.

Behavior/schema changes:
None. Existing thermal-value precedence and derivation, feedback-row shape,
artifact contracts, and deterministic output are preserved.

Last completed slice:
TimelineFeedback thermal context extraction, selected in `4ccc5828` and
implemented in `c3190551`.
`timeline_feedback.ex` moved from 3,153 to 3,061 lines; the dedicated thermal
context owner is 113 lines.

Next candidate:
Re-rank the live largest-module set and select the next cohesive ownership
boundary.

Blocked:
No.
