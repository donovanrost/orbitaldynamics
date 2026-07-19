# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
StationCalendar reservation-source evidence extraction.

Status:
Selected; implementation not started.

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

Verification plan:
- Run the strict warning-clean compile before and after implementation.
- Run the focused StationCalendar regression file and adjacent reservation
  report/review/import consumers selected from live references.
- Run exact old/new public parity from this selection commit across direct
  reservation rows, embedded source entries/overlaps, provider identity
  fallbacks, reservation ID aliases, owned/ambiguous/default match statuses,
  expiration aliases, available/unrelated rows, atom/string keys,
  deterministic outputs, and public errors.
- Run `mix xref callers` for the new owner, inspect compile-connected
  dependents, check formatting and `git diff --check`, prove the removed
  helper family is absent from the facade, and review final facade/owner
  boundaries.

Behavior/schema changes:
None intended.

Last completed slice:
RecommendationRiskContext timeline-publication extraction, selected in
`6d4b0888` and implemented in `d3e26bb2`.
`recommendation_risk_context.ex` moved from 2,607 to 2,521 lines; the dedicated
timeline-publication owner is 121 lines.

Next candidate:
Implement and verify the selected StationCalendar reservation-source evidence
extraction.

Blocked:
No.
