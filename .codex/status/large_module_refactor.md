# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport station-operations import extraction.

Status:
Completed and published.

Selected boundary:
Extract the command-window, station-calendar, and station-reservation
constructor implementations into
`OrbitalDynamics.CadenceImport.StationOperationsImport`. Preserve all three
public facade entry points and pass the existing review-package import seam as
a callback.

Selection evidence:
- `cadence_import.ex` is now 2,321 lines.
- The selected contiguous family spans about 75 lines and owns ground-station
  window, calendar, and reservation normalization and routing.
- The family has one responsibility: turn station-operations evidence into
  review-package imports while preserving embedded review packages and each
  source-ID fallback chain.
- Public API docs, row construction, manifest assembly, schemas, and adjacent
  contention/contact-planning imports remain outside the boundary.

Verification:
- Strict test compile passed with 3,835 files and warnings as errors.
- Three focused station-operations tests passed with 71 excluded.
- All combined CadenceImport tests passed: 96 tests.
- CadenceImport schema contracts passed: 4 tests.
- An executable before/after proof matched 24 cases across all three
  constructors, including embedded review packages and inferred/explicit IDs.
- Formatting and diff checks passed, and no temporary proof files remain.
- Static ownership checks confirmed all three public facade entry points
  delegate to one implementation owner.
- Runtime xref confirmed `cadence_import.ex` is the direct consumer of
  `station_operations_import.ex`.
- Bounded local review found no embedded-package precedence, normalization,
  source-ID fallback, OperatorReview conversion, source-contract, public API,
  row, ordering, or schema changes.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
CadenceImport station-operations import extraction, selected in `9a01044d` and
implemented in `f6122db5`. `cadence_import.ex` moved from 2,321 to 2,283 lines;
the extracted owner is 59 lines.

Next candidate:
Re-inventory remaining public routing after station-operations imports have
one production owner.

Blocked:
No.
