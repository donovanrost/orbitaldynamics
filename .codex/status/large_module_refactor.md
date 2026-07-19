# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
TimelineFeedback station-calendar context extraction.

Status:
Selected; implementation pending.

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
Pending.

Behavior/schema changes:
None intended. This is a facade-preserving production ownership extraction.

Last completed slice:
StationCalendar provider-contention extraction, selected in `65de2bc1` and
implemented in `addd1606`.
`station_calendar.ex` moved from 3,487 to 3,346 lines; the dedicated
provider-contention owner is 271 lines.

Next candidate:
Re-rank the live largest-module set and select the next cohesive ownership
boundary.

Blocked:
No.
