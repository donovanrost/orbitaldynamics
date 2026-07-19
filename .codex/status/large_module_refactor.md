# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
LinkCapacity station-availability extraction.

Status:
Selected; implementation not started.

Selected boundary:
Extract station-unavailability aliases, availability precedence, contact and
source-calendar candidate collection, status normalization, highest-severity
selection, row canonicalization, and capacity-fraction fallback into
`OrbitalDynamics.Communications.LinkCapacity.StationAvailability`. Preserve the
LinkCapacity facade through private availability/metadata delegates.

Selection evidence:
- Live re-ranking places `communications/link_capacity.ex` at 2,554 lines, the
  largest eligible facade behind Schema, Timeline, MissionPlan.Activity, and
  the root public facade.
- The selected policy is declared at lines 13-21 and implemented at lines
  2,422-2,513, with its normalization delegate at lines 2,544-2,546.
- Report construction, capacity adjustment, and summary routing consume the
  responsibility only through `station_availability/1` and
  `contact_station_availability/1`; capability/assumption maps consume its two
  metadata values.
- Throughput calculations, station reservation evidence, input triage,
  approval policy, public report/summary clauses, relay routing, and artifact
  contracts remain outside this boundary.
- Existing alias canonicalization, severity precedence, nested source lookup,
  maintenance/outage collapse, capacity-fraction fallback, nil behavior,
  capability metadata, and deterministic output must remain unchanged.

Verification plan:
- Run the strict warning-clean compile before and after implementation.
- Run the focused LinkCapacity regression file and adjacent capacity
  review/import/summary consumers selected from live references.
- Run exact old/new public parity from this selection commit across direct and
  nested availability evidence, aliases, mixed precedence, contact lists,
  reduced-capacity fallback, available/unknown/nil values, capability
  metadata, deterministic reports/summaries, and public errors.
- Run `mix xref callers` for the new owner, inspect compile-connected
  dependents, check formatting and `git diff --check`, prove the removed
  policy family is absent from the facade, and review final facade/owner
  boundaries.

Behavior/schema changes:
None intended.

Last completed slice:
StationCalendar reservation-source evidence extraction, selected in
`d5c47875` and implemented in `77f354df`.
`communications/station_calendar.ex` moved from 2,595 to 2,425 lines; the
dedicated reservation-source owner is 227 lines.

Next candidate:
Implement and verify the selected LinkCapacity station-availability
extraction.

Blocked:
No.
