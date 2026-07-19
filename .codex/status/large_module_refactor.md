# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport timeline review import orchestration extraction.

Status:
Selected; implementation has not started.

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
Pending: representative focused timeline baselines, exact old/new constructor
equivalence proof, strict compile, all combined CadenceImport tests, schema
contracts, static single ownership, runtime xref, and bounded review.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
CadenceImport review-row dispatch extraction, selected in `8852f976` and
implemented in `000148a8`. `cadence_import.ex` moved from 2,777 to 2,708 lines;
the extracted owner is 47 lines.

Next candidate:
Re-inventory remaining public routing after timeline review imports have one
production owner.

Blocked:
No.
