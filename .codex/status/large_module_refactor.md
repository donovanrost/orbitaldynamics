# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport review-row dispatch extraction.

Status:
Completed and published.

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
- Strict test compile passed with 3,826 files and warnings as errors.
- Three focused representative dispatch tests passed with 69 excluded.
- All combined CadenceImport tests passed: 96 tests.
- CadenceImport schema contracts passed: 4 tests.
- A direct dispatch proof covered all 36 explicit review-type mappings and 10
  representative accepted-but-generic or unknown fallback types.
- Formatting and diff checks passed, and no temporary proof files remain.
- Static ownership checks confirmed the dispatch table has one production
  implementation behind the preserved facade callback map.
- Runtime xref confirmed `cadence_import.ex` is the direct consumer of
  `review_row_dispatch.ex`.
- Bounded local review found no mapping, shared contention callback,
  suppression variant, generic fallback, rank, row shape, ordering, or schema
  changes.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
CadenceImport review-row dispatch extraction, selected in `8852f976` and
implemented in `000148a8`. `cadence_import.ex` moved from 2,777 to 2,708 lines;
the extracted owner is 47 lines.

Next candidate:
Return to remaining public routing after review-row dispatch has one production
owner.

Blocked:
No.
