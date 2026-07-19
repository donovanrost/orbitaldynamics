# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
LinkCapacity station-availability extraction.

Status:
Completed and pushed.

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

Implementation:
- Selection was recorded and pushed in `824e5611`.
- Implementation was committed and pushed in `f2c45f2e`.
- `communications/link_capacity.ex` moved from 2,554 to 2,462 lines.
- `OrbitalDynamics.Communications.LinkCapacity.StationAvailability` is a
  116-line owner reached through private availability and metadata delegates.

Verification:
- Strict warning-clean compilation passed across 3,961 files.
- The focused LinkCapacity file and four adjacent review/import/replay/schema
  consumers passed together: 64 tests.
- Exact old/new public parity passed for 7 cases covering capability metadata,
  empty reports, direct/nested aliases, maintenance/outage precedence,
  reserved/reduced capacity, capacity-fraction fallback, available/unknown
  evidence, summary routing, deterministic output, and the public error path.
- `mix xref callers` reports only the LinkCapacity facade; the
  compile-connected graph reports the new owner and facade.
- The removed policy family is absent from the facade, formatting and
  `git diff --check` passed, and the final diff is ownership-only.

Behavior/schema changes:
None intended.

Last completed slice:
LinkCapacity station-availability extraction, selected in `824e5611` and
implemented in `f2c45f2e`. `communications/link_capacity.ex` moved from 2,554
to 2,462 lines; the dedicated station-availability owner is 116 lines.

Next candidate:
Re-rank the live checkout and select the next cohesive facade-preserving
boundary.

Blocked:
No.
