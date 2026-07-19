# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
StationCalendar precedence-summary extraction.

Status:
Selected; strict focused baseline pending.

Selected boundary:
Extract row-derived station-calendar availability precedence aggregation,
higher-precedence reservation surfacing, contact/reservation routing maps, and
precedence-specific list/count helpers into
`OrbitalDynamics.Communications.StationCalendar.PrecedenceSummary`. Preserve
all StationCalendar and root public facades.

Selection evidence:
- Excluding the generated/declarative candidate-refresh JSON-schema module,
  live re-ranking places `communications/station_calendar.ex` at 2,068 lines,
  the largest ordinary eligible facade.
- StationCalendar already delegates to twelve responsibility-focused owners;
  its precedence-summary builder remains in the facade at lines 801-876 with a
  cohesive set of precedence-specific routing helpers near lines 1,823-1,914.
- The new owner will receive facade-owned schema/model-limit values explicitly,
  avoiding ownership changes to public dispatch or capability contracts.
- Contact overlay, station matching, provider contention/counteroffers,
  reservation reports and hold readiness, approval policy, capacity handling,
  feedback validation, and shared facade aggregators remain outside the
  boundary.
- Exact string/atom input parity, source/default selection, sparse output,
  deterministic sorting, counts, applied/overlap routing, higher-precedence
  reservation routing, and pass-through summary behavior must remain unchanged.

Implementation:
Pending.

Verification:
Pending strict focused baseline, exact old/new public parity, focused and
adjacent tests, static ownership checks, xref, strict warning-clean compile,
formatting, and diff checks.

Behavior/schema changes:
None intended.

Last completed slice:
ContactIntent provider-result normalization extraction, selected in
`7b01da01` and implemented in `54820d60`.
`communications/contact_intent.ex` moved from 2,112 to 2,038 lines; the
dedicated provider-result owner is 77 lines.

Next candidate:
Complete the selected StationCalendar precedence-summary extraction.

Blocked:
No.
