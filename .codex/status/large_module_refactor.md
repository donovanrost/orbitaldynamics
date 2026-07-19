# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
StationCalendar availability and capacity normalization extraction.

Status:
Selected; implementation pending.

Selected boundary:
Extract the availability/alias contract, capacity fraction and percent
interpretation, unavailable/reservation normalization, status tokenization,
and numeric validation into
`OrbitalDynamics.Communications.StationCalendar.Availability`.
Preserve the existing StationCalendar public API facade.

Selection evidence:
- Live re-ranking places `station_calendar.ex` at 3,655 lines, fourth behind
  Schema, Timeline, and MissionPlan.Activity and ahead of Manifest,
  ResourceProjection, TimelineFeedback, ContactAllocation,
  RecommendationRiskContext, OrbitalDynamics, and LinkCapacity.
- The selected family owns one provider-boundary responsibility used by raw
  entry validation, ground-network conversion, overlay precedence, and
  capability metadata: canonical availability and capacity interpretation.
- Contact matching, direction handling, reservations, counteroffers, policy
  decisions, feedback evidence, and artifact assembly remain outside this
  boundary.
- Existing aliases, precedence, numeric-string/percent handling, range
  validation, fallback-to-full behavior, error text, and deterministic output
  remain unchanged.

Verification:
Pending.

Behavior/schema changes:
None intended. This is a facade-preserving production ownership extraction.

Last completed slice:
LinkCapacity contact-feedback aggregation extraction, selected in `8fb99b99`
and implemented in `cc37865f`.
`link_capacity.ex` moved from 3,656 to 3,520 lines; the dedicated
contact-feedback owner is 166 lines.

Next candidate:
Re-rank the live largest-module set and select the next cohesive ownership
boundary.

Blocked:
No.
