# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema station-calendar owner routing extraction.

Status:
Selected; implementation pending.

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
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. Required fields, validation ordering and paths, public `Schema`
and existing `StationReservationValidation` APIs, validation results, and
checked-in exports must remain unchanged.

Last completed slice:
Schema link-capacity owner completion, selected in `e74cce47` and implemented
in `a5337b46`.
`schema.ex` moved from 4,773 to 4,771 lines.

Next candidate:
Implement and verify the selected station-calendar owner routing, then re-rank
the remaining Schema responsibility clusters.

Blocked:
No.
