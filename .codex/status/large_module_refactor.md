# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport operational-timeline import extraction.

Status:
Selected; implementation has not started.

Selected boundary:
Extract the timeline-feedback and operational-timeline report constructor
implementations into
`OrbitalDynamics.CadenceImport.OperationalTimelineImport`. Preserve both public
facade entry points and pass the existing review-package import seam as a
callback.

Selection evidence:
- `cadence_import.ex` is now 2,254 lines.
- The selected contiguous pair spans about 40 lines and owns operational
  timeline feedback/report normalization, conversion, and routing.
- The pair has one responsibility: turn realized feedback and operational
  timeline evidence into review-package imports while preserving feedback's
  embedded-package precedence.
- Public API docs, row construction, manifest assembly, schemas, and adjacent
  repair/contention imports remain outside the boundary.

Verification:
Pending: focused operational-timeline baselines, exact old/new constructor
equivalence proof, strict compile, all combined CadenceImport tests, schema
contracts, static single ownership, runtime xref, and bounded review.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
CadenceImport contact-contention import extraction, selected in `49981283` and
implemented in `0a9e4823`. `cadence_import.ex` moved from 2,283 to 2,254 lines;
the extracted owner is 37 lines.

Next candidate:
Re-inventory remaining public routing after operational-timeline imports have
one production owner.

Blocked:
No.
