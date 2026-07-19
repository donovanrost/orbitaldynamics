# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
StationCalendar calendar-input normalization extraction.

Status:
Completed and pushed.

Selected boundary:
Extract provider artifact conversion, provider/declared entry flattening,
stable provider and entry identity validation, interval validation,
capacity/availability normalization, reservation and counteroffer metadata
normalization, and deterministic calendar sorting into
`OrbitalDynamics.Communications.StationCalendar.CalendarInput`.
Preserve the existing StationCalendar public API facade.

Selection evidence:
- Live re-ranking places `communications/station_calendar.ex` at 3,346 lines,
  fourth behind Schema, Timeline, and MissionPlan.Activity and ahead of
  ContactAllocation, RecommendationRiskContext, TimelineFeedback, Manifest,
  OperationalReadiness, ContactContention, LinkCapacity, and
  ResourceProjection.
- The selected family owns the intake boundary used by both
  `overlay_contacts/3` and provider-counteroffer report construction before
  matching or report assembly begins.
- Contact matching, precedence selection, annotation, reservation summaries,
  provider contention, approval policy, and report assembly remain outside
  this boundary.
- Existing provider alias precedence, generated IDs, capacity validation,
  availability rules, interval errors, reservation/counteroffer fields,
  omission behavior, and deterministic sorting remain unchanged.

Verification:
- Focused baseline before implementation:
  `test/orbital_dynamics/communications/station_calendar_test.exs` passed
  42 tests.
- Strict compilation after implementation:
  `MIX_ENV=test MIX_OS_CONCURRENCY_LOCK=0 mix compile --force --warnings-as-errors`
  compiled 3,933 files successfully.
- Focused regression:
  `test/orbital_dynamics/communications/station_calendar_test.exs` passed
  42 tests.
- Adjacent regressions:
  `test/orbital_dynamics/operator_review/station_calendar_test.exs` passed
  3 tests and
  `test/orbital_dynamics/campaign_planner/repair_contact_allocation_contention_test.exs`
  passed 1 test.
- Exact old/new comparison against selection commit `8c62649c` covered six
  calendar/provider states across `to_ground_network/1` and
  `overlay_contacts/3`; all 12 outputs matched exactly.
- The exact states covered nil input, provider aliases, generated IDs,
  reservation and counteroffer metadata, direction normalization, capacity
  normalization, provider artifacts, multi-provider input, and invalid
  intervals.
- `git diff --check` passed.
- `mix xref callers
  OrbitalDynamics.Communications.StationCalendar.CalendarInput` reports only
  the StationCalendar facade as a runtime caller; compile-connected xref
  reports no unexpected coupling.
- Static review confirmed input-exclusive identity, interval, capacity,
  reservation, and counteroffer normalization helpers moved to the owner while
  matching, annotation, summary, contention, and policy helpers remain in the
  facade.

Behavior/schema changes:
None. Existing provider aliases, generated identities, interval errors,
capacity and availability normalization, reservation/counteroffer fields,
omission behavior, artifact shape, and deterministic sorting are preserved.

Last completed slice:
StationCalendar calendar-input normalization extraction, selected in
`8c62649c` and implemented in `31df3bf1`.
`communications/station_calendar.ex` moved from 3,346 to 2,981 lines; the
dedicated calendar-input owner is 449 lines.

Next candidate:
Re-rank the live largest-module set and select the next cohesive ownership
boundary.

Blocked:
No.
