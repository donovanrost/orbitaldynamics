# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
StationCalendar calendar-input normalization extraction.

Status:
Selected; implementation pending.

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
Pending.

Behavior/schema changes:
None intended. This is a facade-preserving production ownership extraction.

Last completed slice:
Manifest target-catalog input extraction, selected in `2769ef8f` and
implemented in `cc2431e8`.
`study/manifest.ex` moved from 3,357 to 3,234 lines; the dedicated
target-catalog input owner is 159 lines.

Next candidate:
Re-rank the live largest-module set and select the next cohesive ownership
boundary.

Blocked:
No.
