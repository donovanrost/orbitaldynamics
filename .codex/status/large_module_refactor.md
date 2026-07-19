# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport station-operations import extraction.

Status:
Selected; implementation has not started.

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
Pending: focused station-operations baselines, exact old/new constructor
equivalence proof, strict compile, all combined CadenceImport tests, schema
contracts, static single ownership, runtime xref, and bounded review.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
CadenceImport contact-planning import extraction, selected in `51ef8061` and
implemented in `9c2864d2`. `cadence_import.ex` moved from 2,352 to 2,321 lines;
the extracted owner is 89 lines.

Next candidate:
Re-inventory remaining public routing after station-operations imports have
one production owner.

Blocked:
No.
