# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
ContactContention timing metrics extraction.

Status:
Completed and pushed.

Selected boundary:
Extract interval validation, contention-window duration, summed contact
duration, union overlap duration, maximum concurrency, and overlapping-pair
count into `OrbitalDynamics.Communications.ContactContention.TimingMetrics`.
Preserve the existing ContactContention public API facade.

Selection evidence:
- Live re-ranking places `communications/contact_contention.ex` at 3,114
  lines, fourth behind Schema, Timeline, and MissionPlan.Activity and ahead of
  LinkCapacity, Manifest, RecommendationRiskContext, ContactAllocation,
  TimelineFeedback, ResourceProjection, StationCalendar, and
  OperationalReadiness.
- The selected family is one independent five-field projection merged into
  both ground-station and spacecraft contention groups; it owns only interval
  arithmetic and not grouping or recommendation decisions.
- Contact normalization, identity validation, group formation, station
  calendar and feedback context, capacity inference, approval policy, and
  resolution policy remain outside this boundary.
- Existing invalid-interval omission, half-open overlap semantics,
  same-timestamp event coalescing, duration arithmetic, pair counting, empty
  output behavior, and deterministic output remain unchanged.

Verification:
- Focused baseline before implementation:
  `test/orbital_dynamics/communications/contact_contention_test.exs` passed
  40 tests.
- Strict compilation after implementation:
  `MIX_ENV=test MIX_OS_CONCURRENCY_LOCK=0 mix compile --force --warnings-as-errors`
  compiled 3,940 files successfully.
- Focused regression:
  `test/orbital_dynamics/communications/contact_contention_test.exs` passed
  40 tests.
- Adjacent regression:
  `test/orbital_dynamics/operator_review/contact_contention_test.exs` passed
  3 tests.
- Exact old/new comparison against selection commit `ee124dce` exposed the
  selected private reducer and compared seven contact sets; all 7 timing maps
  matched exactly.
- The exact inputs covered empty and single intervals, invalid intervals,
  touching intervals, two-way and three-way overlap, same-timestamp event
  coalescing, integer/float arithmetic, and ignored string values.
- `git diff --check` passed.
- `mix xref callers
  OrbitalDynamics.Communications.ContactContention.TimingMetrics` reports only
  the ContactContention facade as a runtime caller; compile-connected xref
  reports no unexpected coupling.
- Static review confirmed the owner exposes only `build/1`; grouping,
  identity, feedback, station-capacity, approval, and resolution-policy
  responsibilities remain outside the boundary.

Behavior/schema changes:
None. Existing timing arithmetic, contention-group shape, artifact contracts,
and deterministic output are preserved.

Last completed slice:
ContactContention timing metrics extraction, selected in `ee124dce` and
implemented in `e03e56d2`.
`communications/contact_contention.ex` moved from 3,114 to 3,035 lines; the
dedicated timing-metrics owner is 91 lines.

Next candidate:
Re-rank the live largest-module set and select the next cohesive ownership
boundary.

Blocked:
No.
