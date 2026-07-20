# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema station-calendar owner routing extraction.

Status:
Completed and pushed.

Selected boundary:
Extend `StationReservationValidation` owner-default routing to
`station_calendar_provider.v1`, `station_calendar_report.v1`, and
`station_calendar_precedence_summary.v1`. Derive requirements from
`StationCalendarRegistryContracts`, route all three direct `Schema` clauses,
and preserve every existing owner API.

Selection evidence:
- `schema.ex` remains the dominant production hotspot at 4,771 lines; the other
  targeted public facades are now 164 to 524 lines.
- The three clauses form the exact `StationCalendarRegistryContracts` family
  and repeat required-field setup.
- `StationReservationValidation` already owns calendar report model and
  model-limit defaults.
- Provider and precedence contract modules own all remaining artifact-specific
  validation.
- No route needs recursive `Schema` lookup.

Implementation:
Extended the registry-backed `StationReservationValidation` owner with three
compact calendar artifact routes and moved provider, report, and precedence
contract routing behind it. `schema.ex` moved from 4,771 to 4,761 lines.

Verification:
- Strict focused baseline: 62 tests passed.
- Focused plus adjacent station-calendar, validation, operator-review, Cadence
  import, candidate-refresh replay/provider build, campaign-planner
  source/pressure, contract, and export coverage after extraction: 84 tests
  passed.
- Full schema export completed with no checked-in artifact changes.
- Static routing review found exactly the three intended direct facade routes.
- `mix xref trace` confirmed all three runtime calls originate in `schema.ex`.
- Formatting and `git diff --check` passed.
- Strict forced compile passed across 4,086 files with warnings as errors.
- Bounded diff review confirmed registry-owned requirements, owner-default
  report model/model limits, provider/report/precedence contract routing,
  validation ordering, and paths remain unchanged.
- Implementation committed and pushed as `6fd05694`.

Behavior/schema changes:
None. Required fields, validation ordering and paths, public `Schema` and
existing `StationReservationValidation` APIs, validation results, and
checked-in exports remain unchanged.

Last completed slice:
Schema station-calendar owner routing extraction, selected in `49ca11aa` and
implemented in `6fd05694`.
`schema.ex` moved from 4,771 to 4,761 lines.

Next candidate:
Re-rank the remaining Schema responsibility clusters and select the next
facade-preserving extraction.

Blocked:
No.
