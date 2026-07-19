# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport review-row run-input metadata extension.

Status:
Completed and published.

Selected boundary:
Move nonempty `run_input_sources` propagation into the existing
`OrbitalDynamics.CadenceImport.ReviewRowMetadata` owner. Preserve the facade's
existing `put_run_input_sources/2` seam as a delegate.

Selection evidence:
- `cadence_import.ex` is now 2,819 lines.
- The selected two-clause helper propagates row-level source metadata and shares
  the same review-row metadata responsibility as queue/action/context helpers.
- Only nonempty map values are propagated; empty, non-map, and missing values
  leave the destination row unchanged.
- Row construction, provenance construction, schemas, and ordering remain
  outside the boundary.

Verification:
- Strict test compile passed with 3,824 files and warnings as errors.
- One focused run-input-source test passed with 71 excluded.
- All combined CadenceImport tests passed: 96 tests.
- CadenceImport schema contracts passed: 4 tests.
- A 4-case direct matrix covered nonempty map propagation and empty-map,
  non-map, and missing-value suppression.
- Formatting and diff checks passed; no temporary proof files were created.
- Static ownership checks confirmed run-input-source propagation has one
  production implementation behind the preserved facade seam.
- Runtime xref confirmed `cadence_import.ex` directly consumes the extended
  `review_row_metadata.ex`.
- Bounded local review found no guard, propagation, overwrite, row-shape,
  provenance, ordering, or schema changes.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
CadenceImport review-row run-input metadata extension, selected in `de39d347`
and implemented in `840ddfb5`. `cadence_import.ex` moved from 2,819 to 2,816
lines; the shared metadata owner grew from 21 to 27 lines.

Next candidate:
Return to remaining review-package or row dispatch after review-row metadata
propagation has one production owner.

Blocked:
No.
