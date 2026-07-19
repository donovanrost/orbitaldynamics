# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
StationCalendar reservation-source evidence extraction.

Status:
Completed and pushed.

Selected boundary:
Extract reservation-affected/contact-contention predicates, source calendar
entry normalization, reservation/provider identity recovery, overlap
annotation, reservation match-status consolidation, and expiration parsing
into
`OrbitalDynamics.Communications.StationCalendar.ReservationSourceEvidence`.
Preserve the StationCalendar facade through the three private reservation
summary delegates.

Selection evidence:
- Live re-ranking places `communications/station_calendar.ex` at 2,595 lines,
  the largest eligible facade behind Schema, Timeline, MissionPlan.Activity,
  and the root public facade.
- The selected private family spans lines 1,122-1,288 and exclusively owns
  reconstruction of reservation evidence from source station-calendar rows.
- Reservation-summary construction consumes the responsibility through three
  private calls: affected-contact normalization and the affected/contention
  predicates.
- Summary aggregation, public report clauses, reservation review/hold/import
  summaries, provider counteroffers, overlay matching, approval policy, and
  artifact contracts remain outside this boundary.
- Existing direct-row precedence, source-entry filtering, fallback identity
  order, availability/status normalization, sorted stable value sets,
  match-status default/ambiguity behavior, expiration parsing, omission rules,
  and deterministic outputs must remain unchanged.

Implementation:
- Selection was recorded and pushed in `d5c47875`.
- Implementation was committed and pushed in `77f354df`.
- `communications/station_calendar.ex` moved from 2,595 to 2,425 lines.
- `OrbitalDynamics.Communications.StationCalendar.ReservationSourceEvidence`
  is a 227-line owner reached through three private facade delegates.

Verification:
- Strict warning-clean compilation passed across 3,960 files.
- The focused StationCalendar file and four adjacent reservation
  handoff/replay/schema consumers passed together: 61 tests.
- Exact old/new public parity passed for 7 cases covering direct reservation
  rows, embedded source entries and overlaps, provider provenance, reservation
  ID/status/expiration aliases, owned/ambiguous/default matching, ignored
  available rows, contention groups, atom/string keys, and the public error
  path.
- `mix xref callers` reports only the StationCalendar facade; the
  compile-connected graph reports the new owner and facade.
- The removed helper family is absent from the facade, formatting and
  `git diff --check` passed, and the final diff is ownership-only.

Behavior/schema changes:
None intended.

Last completed slice:
StationCalendar reservation-source evidence extraction, selected in
`d5c47875` and implemented in `77f354df`.
`communications/station_calendar.ex` moved from 2,595 to 2,425 lines; the
dedicated reservation-source owner is 227 lines.

Next candidate:
Re-rank the live checkout and select the next cohesive facade-preserving
boundary.

Blocked:
No.
