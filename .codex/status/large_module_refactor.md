# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport station-calendar context field catalog extraction.

Status:
Completed and published.

Selected boundary:
Extract the static station-calendar and reservation context field allowlist into
`OrbitalDynamics.CadenceImport.StationCalendarContextFields`. Preserve the
facade's existing zero-arity callback seam as a delegate for contact-contention
row construction.

Selection evidence:
- `cadence_import.ex` is now 3,428 lines.
- The selected contiguous catalog spans 20 ordered field names and is consumed
  by contact-contention row construction through a stable callback.
- The family has one responsibility: declare which station calendar,
  availability, capacity, and reservation context keys are copied from source
  rows.
- Dispatch, row construction, review actions, map compaction, schemas, ordering
  outside this list, and manifest construction remain outside the boundary.

Verification:
- Strict test compile passed with 3,812 files and warnings as errors.
- One focused contact-contention test passed with 71 excluded.
- All combined CadenceImport tests passed: 96 tests.
- CadenceImport schema contracts passed: 4 tests.
- An AST-derived proof against selection commit `f2d6c001` confirmed exact
  ordered equality for all 20 station-calendar context fields.
- Formatting and diff checks passed, and no temporary proof files remain.
- Static ownership checks confirmed the catalog has one production
  implementation behind the preserved facade callback seam.
- Runtime xref confirmed `cadence_import.ex` is the direct consumer of
  `station_calendar_context_fields.ex`.
- Bounded local review found no callback, membership, order, row-shape,
  compaction, or schema changes.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
CadenceImport station-calendar context field catalog extraction, selected in
`f2d6c001` and implemented in `e7fd5299`. `cadence_import.ex` moved from 3,428
to 3,407 lines; the extracted owner is 28 lines.

Next candidate:
Return to the remaining CadenceImport row-building or manifest-routing helpers
after station-calendar context selection has one production owner.

Blocked:
No.
