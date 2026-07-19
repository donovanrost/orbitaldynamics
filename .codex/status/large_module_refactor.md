# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport review-row run-input metadata extension.

Status:
Selected; implementation has not started.

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
Pending: focused run-input-source baseline, exact propagation matrix, strict
compile, all combined CadenceImport tests, schema contracts, static single
ownership, runtime xref, and bounded review.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
CadenceImport timeline source-identifier policy extension, selected in
`cd5e4d8e` and implemented in `d51df814`. `cadence_import.ex` moved from 2,813
to 2,819 lines because the two explicit facade delegates expanded for readable
argument passing; the shared policy owner grew from 52 to 57 lines.

Next candidate:
Return to remaining review-package or row dispatch after review-row metadata
propagation has one production owner.

Blocked:
No.
