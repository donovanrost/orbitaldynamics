# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport review-row dispatch extraction.

Status:
Selected; implementation has not started.

Selected boundary:
Extract the review-type-to-row-builder dispatch table into
`OrbitalDynamics.CadenceImport.ReviewRowDispatch`. Preserve
`review_manifest_row/2` as the facade seam and pass concrete row-builder
callbacks from the facade; retain the generic builder as the fallback.

Selection evidence:
- `cadence_import.ex` is now 2,777 lines.
- The selected contiguous multimethod spans about 110 lines and maps review
  types to 37 specialized or generic row-builder paths.
- The family has one responsibility: choose the correct builder callback while
  preserving clause order and generic fallback behavior.
- Concrete row building, package orchestration, schemas, and source ordering
  remain outside the boundary.

Verification:
Pending: focused representative dispatch baselines, exact review-type callback
mapping proof, strict compile, all combined CadenceImport tests, schema
contracts, static single ownership, runtime xref, and bounded review.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
CadenceImport operator-review package import extraction, selected in `bbf5093e`
and implemented in `a2013e87`. `cadence_import.ex` moved from 2,816 to 2,777
lines; the extracted owner is 58 lines.

Next candidate:
Return to remaining public routing after review-row dispatch has one production
owner.

Blocked:
No.
