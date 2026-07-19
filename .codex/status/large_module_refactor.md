# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport contact-contention import extraction.

Status:
Selected; implementation has not started.

Selected boundary:
Extract the contact-contention report and resolution-report constructor
implementations into
`OrbitalDynamics.CadenceImport.ContactContentionImport`. Preserve both public
facade entry points and pass the existing review-package import seam as a
callback.

Selection evidence:
- `cadence_import.ex` is now 2,283 lines.
- The selected contiguous pair spans about 55 lines and owns contention
  normalization, embedded-package precedence, conversion, and routing.
- The pair has one responsibility: turn contention detection and resolution
  evidence into review-package imports while preserving their distinct
  fallback IDs and source contracts.
- Public API docs, row construction, manifest assembly, schemas, and adjacent
  timeline/station imports remain outside the boundary.

Verification:
Pending: focused contention baselines, exact old/new constructor equivalence
proof, strict compile, all combined CadenceImport tests, schema contracts,
static single ownership, runtime xref, and bounded review.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
CadenceImport station-operations import extraction, selected in `9a01044d` and
implemented in `f6122db5`. `cadence_import.ex` moved from 2,321 to 2,283 lines;
the extracted owner is 59 lines.

Next candidate:
Re-inventory remaining public routing after contact-contention imports have one
production owner.

Blocked:
No.
