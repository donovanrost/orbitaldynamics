# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
StationCalendar station matching extraction.

Status:
Completed and pushed.

Selected boundary:
Extract contact normalization, contact-row/direction classification,
ground-station/time/direction matching, provider-counteroffer inclusion,
availability precedence, top-entry selection, ambiguous-entry synthesis,
unambiguous capacity/direction preservation, window overlap semantics, and the
advertised command-contact direction aliases into
`OrbitalDynamics.Communications.StationCalendar.StationMatching`. Preserve all
public StationCalendar overlay, report, summary, and capability facades.

Selection evidence:
- Live re-ranking places `communications/station_calendar.ex` at 2,268 lines,
  the largest eligible facade behind Schema, Timeline, MissionPlan.Activity,
  and the root public facade.
- The selected matching family spans lines 1,338-1,507 and exclusively decides
  which normalized calendar entries affect a normalized contact and which
  highest-precedence entry represents the overlap.
- Overlay construction already converges through five private helpers for
  normalization, matching, selected entry, contact counting, and precedence.
- Annotation, reservations, provider contention, approval policy, affected-row
  construction, reports/summaries, public clauses, and artifact contracts
  remain outside this boundary.
- Existing shallow recursive key stringification, station-ID aliasing,
  contact-type fallback directions, command/uplink compatibility, strict-open
  interval overlap, available-entry exclusion except counteroffers, precedence
  ranks, deterministic ambiguous IDs, capacity/direction ambiguity behavior,
  exact errors, and capability metadata must remain unchanged.

Implementation:
- Selection was recorded and pushed in `bd2cead6`.
- Implementation was committed and pushed in `7e6add9c`.
- `communications/station_calendar.ex` moved from 2,268 to 2,068 lines.
- `OrbitalDynamics.Communications.StationCalendar.StationMatching` is a
  237-line owner reached through private facade delegates.

Verification:
- Strict warning-clean compilation passed across 3,978 files.
- The focused StationCalendar file and five adjacent campaign, repair,
  candidate-refresh, operator-review, and schema consumers passed together:
  69 tests.
- Exact old/new public overlay/capability parity passed for 11 cases covering
  empty input, contact type and provider direction aliases, strict-open window
  boundaries, available/counteroffer inclusion, precedence, same/different
  capacity and direction ambiguity, atom-key/station-ID normalization, invalid
  input errors, and capability metadata.
- `mix xref callers` reports only the StationCalendar facade.
- The facade-owned selector, ambiguity, contact normalization, direction/
  window matching, precedence helpers, and direction-policy attributes are
  absent apart from thin delegates, formatting and `git diff --check` passed,
  and the final diff is ownership-only.

Behavior/schema changes:
None intended.

Last completed slice:
StationCalendar station matching extraction, selected in `bd2cead6` and
implemented in `7e6add9c`.
`communications/station_calendar.ex` moved from 2,268 to 2,068 lines; the
dedicated station-matching owner is 237 lines.

Next candidate:
Re-rank the live checkout and select the next cohesive facade-preserving
boundary.

Blocked:
No.
