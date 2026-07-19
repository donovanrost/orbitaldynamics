# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport resource-projection import extraction.

Status:
Selected; implementation has not started.

Selected boundary:
Extract the resource-projection report and flow-summary constructor
implementations into
`OrbitalDynamics.CadenceImport.ResourceProjectionImport`. Preserve both public
facade entry points and pass the existing review-package import seam as a
callback.

Selection evidence:
- `cadence_import.ex` is now 2,371 lines.
- The selected contiguous pair spans about 40 lines and owns projection
  normalization, source-identity, OperatorReview conversion, and source
  contracts.
- The pair has one responsibility: turn resource-projection report and flow
  evidence into review-package imports while preserving their distinct nested
  assumptions-source precedence.
- Public API docs, row construction, manifest assembly, schemas, and adjacent
  contact/candidate imports remain outside the boundary.

Verification:
Pending: focused resource-projection baselines, exact old/new constructor
equivalence proof, strict compile, all combined CadenceImport tests, schema
contracts, static single ownership, runtime xref, and bounded review.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
CadenceImport constraint/objective assessment import extraction, selected in
`1e679c93` and implemented in `5604d4ff`. `cadence_import.ex` moved from 2,384
to 2,371 lines; the extracted owner is 45 lines.

Next candidate:
Re-inventory remaining public routing after resource-projection imports have
one production owner.

Blocked:
No.
