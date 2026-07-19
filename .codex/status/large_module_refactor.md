# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
StationCalendar availability and capacity normalization extraction.

Status:
Completed and pushed in `8cf68232`.

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
- Strict test-environment compile passed with warnings as errors across 3,920
  files.
- Focused StationCalendar coverage passed: 42 tests.
- Adjacent station-calendar operator-review coverage passed: 3 tests.
- Exact public old/new comparison against selection commit `6c271bee` passed
  for capability metadata, ground-network conversion, contact overlay, and
  report outputs across ten availability/capacity shapes plus identical errors
  for three invalid fraction/availability cases.
- `mix xref callers` reports only the StationCalendar facade as a runtime
  caller of the extracted availability owner.
- Static ownership checks confirm availability aliases, numeric/status
  normalization, capacity interpretation, and range validation live in the
  dedicated owner while matching and artifact responsibilities remain in the
  facade.
- `git diff --check` passed.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
StationCalendar availability and capacity normalization extraction, selected
in `6c271bee` and implemented in `8cf68232`.
`station_calendar.ex` moved from 3,655 to 3,487 lines; the dedicated
availability owner is 205 lines.

Next candidate:
Re-rank the live largest-module set and select the next cohesive ownership
boundary.

Blocked:
No.
