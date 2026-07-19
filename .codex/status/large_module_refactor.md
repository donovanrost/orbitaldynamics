# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport maneuver import extraction.

Status:
Completed and published.

Selected boundary:
Extract the three maneuver recommendation, execution-delta, and review-report
constructor implementations into
`OrbitalDynamics.CadenceImport.ManeuverReviewImport`. Preserve every public
facade entry point and pass the existing review-package import seam as a
callback.

Selection evidence:
- `cadence_import.ex` is now 2,411 lines.
- The selected contiguous family spans about 55 lines and owns the three
  maneuver-specific normalization, source-identity, OperatorReview conversion,
  and source-contract paths.
- The family has one responsibility: turn maneuver evidence into
  review-package imports while preserving each artifact's distinct ID
  precedence.
- Public API docs, row construction, manifest assembly, schemas, and adjacent
  constraint/objective imports remain outside the boundary.

Verification:
- Strict test compile passed with 3,831 files and warnings as errors.
- Three focused maneuver constructor tests passed with 69 excluded.
- All combined CadenceImport tests passed: 96 tests.
- CadenceImport schema contracts passed: 4 tests.
- An executable before/after proof matched 18 cases across all three
  constructors, three key/source-ID shapes, and inferred versus explicit IDs.
- Formatting and diff checks passed, and no temporary proof files remain.
- Static ownership checks confirmed all three public facade entry points
  delegate to one implementation owner.
- Runtime xref confirmed `cadence_import.ex` is the direct consumer of
  `maneuver_review_import.ex`.
- Bounded local review found no normalization, source-ID precedence or
  fallback, OperatorReview conversion, source-contract, public API, row,
  ordering, or schema changes.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
CadenceImport maneuver import extraction, selected in `c89cd4aa` and
implemented in `66a19fe0`. `cadence_import.ex` moved from 2,411 to 2,384 lines;
the extracted owner is 57 lines.

Next candidate:
Re-inventory remaining public routing after maneuver imports have one
production owner.

Blocked:
No.
