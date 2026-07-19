# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport timeline review import orchestration extraction.

Status:
Completed and published.

Selected boundary:
Extract the 15 timeline report, summary, state, and preservation public
constructor implementations into
`OrbitalDynamics.CadenceImport.TimelineReviewImport`. Preserve every public
`CadenceImport.from_timeline_*` entry point as a thin facade delegate and pass
the existing review-package import seam as a callback.

Selection evidence:
- `cadence_import.ex` is now 2,708 lines.
- The selected contiguous family spans about 250 lines and owns the repeated
  normalization, source-identifier choice, OperatorReview conversion, and
  source-contract routing for 15 related timeline artifact shapes.
- The boundary is cohesive around timeline review-package construction; public
  API docs and entry points stay on the facade.
- Review-row construction, manifest assembly, schema contracts, generic
  dispatch, and non-timeline imports remain outside the boundary.

Verification:
- Strict test compile passed with 3,827 files and warnings as errors.
- Four representative timeline constructor tests passed with 72 excluded.
- All combined CadenceImport tests passed: 96 tests.
- CadenceImport schema contracts passed: 4 tests.
- An executable before/after proof matched 90 cases across all 15 constructors,
  three key-shape/source-ID inputs, and inferred versus explicit source IDs.
- Formatting and diff checks passed, and no temporary proof files remain.
- Static ownership checks confirmed all 15 public facade entry points delegate
  to one implementation owner.
- Runtime xref confirmed `cadence_import.ex` is the direct consumer of
  `timeline_review_import.ex`.
- Bounded local review found no normalization, source-ID precedence, fallback,
  approval-policy, OperatorReview conversion, source-contract, public API,
  row, ordering, or schema changes.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
CadenceImport timeline review import orchestration extraction, selected in
`893716e0` and implemented in `fd48e3cf`. `cadence_import.ex` moved from 2,708
to 2,573 lines; the extracted owner is 221 lines.

Next candidate:
Re-inventory remaining public routing after timeline review imports have one
production owner.

Blocked:
No.
