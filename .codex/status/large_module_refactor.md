# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport resource-projection import extraction.

Status:
Completed and published.

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
- Strict test compile passed with 3,833 files and warnings as errors.
- Two focused resource-projection tests passed with 70 excluded.
- All combined CadenceImport tests passed: 96 tests.
- CadenceImport schema contracts passed: 4 tests.
- An executable before/after proof matched 12 cases across both constructors,
  three key/source-ID shapes, and inferred versus explicit IDs.
- Formatting and diff checks passed, and no temporary proof files remain.
- Static ownership checks confirmed both public facade entry points delegate to
  one implementation owner.
- Runtime xref confirmed `cadence_import.ex` is the direct consumer of
  `resource_projection_import.ex`.
- Bounded local review found no normalization, source-ID precedence or
  fallback, OperatorReview conversion, source-contract, public API, row,
  ordering, or schema changes.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
CadenceImport resource-projection import extraction, selected in `04cad874`
and implemented in `82f89a5d`. `cadence_import.ex` moved from 2,371 to 2,352
lines; the extracted owner is 45 lines.

Next candidate:
Re-inventory remaining public routing after resource-projection imports have
one production owner.

Blocked:
No.
