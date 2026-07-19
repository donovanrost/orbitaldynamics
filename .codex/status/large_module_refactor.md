# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
TimelineFeedback station-calendar context extraction.

Status:
Completed and pushed.

Selected boundary:
Extract station-calendar feedback context assembly, capacity fraction/path
normalization, reservation expiration/overlap consolidation, provider
identity, ambiguity, trust, and reservation metadata into
`OrbitalDynamics.TimelineFeedback.StationCalendarContext`.
Preserve the existing TimelineFeedback public API facade.

Selection evidence:
- Live re-ranking places `timeline_feedback.ex` at 3,452 lines, fourth behind
  Schema, Timeline, and MissionPlan.Activity and ahead of ResourceProjection,
  Manifest, StationCalendar, ContactAllocation, RecommendationRiskContext,
  OperationalReadiness, and ContactContention.
- The selected family owns one reconciliation-context responsibility reused by
  planned and realized feedback rows: normalizing station-calendar capacity,
  provider, ambiguity, reservation, overlap, and trust evidence.
- Reconciliation/matching, realized-input validation, product/resource/link
  contexts, operational feedback, and artifact assembly remain outside this
  boundary.
- Existing path precedence, fraction/percent validation, list normalization,
  expiration alias handling, omission behavior, and deterministic output remain
  unchanged.

Verification:
- Focused baseline before implementation:
  `test/orbital_dynamics/timeline_feedback_test.exs` passed 73 tests.
- Strict compilation after implementation:
  `MIX_ENV=test MIX_OS_CONCURRENCY_LOCK=0 mix compile --force --warnings-as-errors`
  compiled 3,930 files successfully.
- Focused regression:
  `test/orbital_dynamics/timeline_feedback_test.exs` passed 73 tests.
- Adjacent timeline regression:
  `test/orbital_dynamics/timeline_test.exs` passed 109 tests.
- Adjacent station-calendar regressions:
  `test/orbital_dynamics/operator_review/station_calendar_test.exs` passed
  3 tests and
  `test/orbital_dynamics/communications/station_calendar_test.exs` passed
  42 tests.
- Exact old/new comparison against selection commit `8b6914d7` covered six
  station-calendar states across `reconcile/3`,
  `normalize_realized_activity/2`, and `activity_state/3`; all 18 outputs
  matched exactly.
- `git diff --check` passed.
- `mix xref callers
  OrbitalDynamics.TimelineFeedback.StationCalendarContext` reports only the
  TimelineFeedback facade as a runtime caller; compile-connected xref reports
  no unexpected coupling.
- Static review confirmed the facade retains station-capacity capability
  metadata, shared non-calendar string normalization, reconciliation, and all
  public APIs while the owner exposes only `build/1`.

Behavior/schema changes:
None. Existing path precedence, capacity validation, provider identity,
reservation-expiration consolidation, list normalization, omission behavior,
artifact shape, and deterministic output are preserved.

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
