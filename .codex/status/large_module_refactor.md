# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport station-calendar context field catalog extraction.

Status:
Selected; implementation has not started.

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
Pending: focused contact-contention baseline, exact ordered catalog equivalence
proof, strict compile, all combined CadenceImport tests, schema contracts,
static single ownership, runtime xref, and bounded review.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
CadenceImport branch-evidence field catalog extraction, selected in `d4c737af`
and implemented in `bac4dd7e`. `cadence_import.ex` moved from 3,536 to 3,428
lines; the extracted owner is 121 lines.

Next candidate:
Return to the remaining CadenceImport row-building or manifest-routing helpers
after station-calendar context selection has one production owner.

Blocked:
No.
