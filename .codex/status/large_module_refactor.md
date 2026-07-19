# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport strategy-review orchestration extraction.

Status:
Selected; implementation has not started.

Selected boundary:
Extract strategy review-package fallback, review-count fallback, and filtered
manifest-row orchestration into `OrbitalDynamics.CadenceImport.StrategyReview`.
Preserve the facade's existing three private seams as delegates; pass
stringification and row-dispatch callbacks into the row orchestrator.

Selection evidence:
- `cadence_import.ex` is now 2,825 lines.
- The selected adjacent family spans about 20 lines and owns strategy-specific
  review package selection, count fallback, row filtering, rank assignment, and
  dispatch.
- Review-type membership now has one extracted policy owner that the
  orchestrator can call directly.
- Strategy artifact parsing, concrete row builders, schemas, and final manifest
  assembly remain outside the boundary.

Verification:
Pending: focused strategy-review baseline, exact orchestration decision matrix,
strict compile, all combined CadenceImport tests, schema contracts, static
single ownership, runtime xref, and bounded review.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
CadenceImport review-type inclusion policy extraction, selected in `7f604aa3`
and implemented in `cc8132e5`. `cadence_import.ex` moved from 2,876 to 2,825
lines; the extracted owner is 60 lines.

Next candidate:
Return to remaining review-package or row dispatch after strategy-review
orchestration has one production owner.

Blocked:
No.
