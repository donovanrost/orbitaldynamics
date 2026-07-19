# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
StationCalendar provider-contention extraction.

Status:
Completed and pushed in `addd1606`.

Selected boundary:
Extract provider-calendar pairwise station/direction/window conflict
detection, overlap identity/evidence, reservation/provider metadata, and
deterministic contention-group construction into
`OrbitalDynamics.Communications.StationCalendar.ProviderContention`.
Preserve the existing StationCalendar public API facade.

Selection evidence:
- Live re-ranking places `station_calendar.ex` at 3,487 lines, fourth behind
  Schema, Timeline, and MissionPlan.Activity and ahead of TimelineFeedback,
  ResourceProjection, Manifest, ContactAllocation, RecommendationRiskContext,
  OperationalReadiness, and LinkCapacity.
- The selected family owns one independent review-evidence responsibility:
  detecting overlapping provider entries that compete for the same compatible
  station direction and producing deterministic contention groups.
- Provider artifact normalization, contact overlay/matching, reservation
  review/import summaries, approval policy, and counteroffer workflows remain
  outside this boundary.
- Existing pair ordering, command/uplink compatibility, open-window overlap
  behavior, group IDs, reservation/provider metadata, omission rules, and
  deterministic output remain unchanged.

Verification:
- Strict test-environment compile passed with warnings as errors across 3,929
  files.
- Focused StationCalendar coverage passed: 42 tests.
- Adjacent station-calendar operator-review and schema-contract coverage
  passed: 3 tests.
- Exact public old/new comparison against selection commit `65de2bc1` passed
  for six calendar states and three public outputs per state: station-calendar
  report, reservation report, and precedence summary.
- `mix xref callers` reports only the StationCalendar facade as a runtime
  caller of the extracted provider-contention owner.
- Static ownership checks confirm pairwise station/direction/window conflict
  detection, group IDs, overlap evidence, and provider/reservation metadata
  live in the dedicated owner while overlay and review-summary responsibilities
  remain in the facade.
- `git diff --check` passed.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

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
