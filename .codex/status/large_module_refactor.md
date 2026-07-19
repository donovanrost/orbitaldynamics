# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport constraint/objective assessment import extraction.

Status:
Completed and published.

Selected boundary:
Extract the constraint-report and objective-satisfaction constructor
implementations into
`OrbitalDynamics.CadenceImport.ConstraintObjectiveImport`. Preserve both public
facade entry points and pass the existing review-package import seam as a
callback.

Selection evidence:
- `cadence_import.ex` is now 2,384 lines.
- The selected contiguous pair spans about 35 lines and owns assessment
  normalization, source-identity, OperatorReview conversion, and source
  contracts.
- The pair has one responsibility: turn constraint and objective-satisfaction
  evidence into review-package imports while preserving the constraint
  assumptions-source fallback.
- Public API docs, row construction, manifest assembly, schemas, and adjacent
  candidate/maneuver/resource-projection imports remain outside the boundary.

Verification:
- Strict test compile passed with 3,832 files and warnings as errors.
- Two focused assessment constructor tests passed with 70 excluded.
- All combined CadenceImport tests passed: 96 tests.
- CadenceImport schema contracts passed: 4 tests.
- An executable before/after proof matched 12 cases across both constructors,
  three key/source-ID shapes, and inferred versus explicit IDs.
- Formatting and diff checks passed, and no temporary proof files remain.
- Static ownership checks confirmed both public facade entry points delegate to
  one implementation owner.
- Runtime xref confirmed `cadence_import.ex` is the direct consumer of
  `constraint_objective_import.ex`.
- Bounded local review found no normalization, source-ID precedence or
  fallback, OperatorReview conversion, source-contract, public API, row,
  ordering, or schema changes.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
CadenceImport constraint/objective assessment import extraction, selected in
`1e679c93` and implemented in `5604d4ff`. `cadence_import.ex` moved from 2,384
to 2,371 lines; the extracted owner is 45 lines.

Next candidate:
Re-inventory remaining public routing after constraint/objective imports have
one production owner.

Blocked:
No.
