# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport strategy-review orchestration extraction.

Status:
Completed and published.

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
- Strict test compile passed with 3,824 files and warnings as errors.
- Two focused strategy-review tests passed with 70 excluded.
- All combined CadenceImport tests passed: 96 tests.
- CadenceImport schema contracts passed: 4 tests.
- A 5-case direct orchestration matrix covered filtering, atom-key
  normalization, starting-rank continuity, explicit/fallback counts, missing
  rows, and embedded-package precedence; integrated tests cover generated
  package fallback.
- Formatting and diff checks passed, and no temporary proof files remain.
- Static ownership checks confirmed package selection, count fallback, and row
  orchestration have one production implementation behind preserved facade
  seams.
- Runtime xref confirmed `cadence_import.ex` is the direct consumer of
  `strategy_review.ex`.
- Bounded local review found no filter, normalization, rank, dispatch, count,
  package fallback, ordering, or schema changes.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
CadenceImport strategy-review orchestration extraction, selected in `4ace6e1e`
and implemented in `4eb8beeb`. `cadence_import.ex` moved from 2,825 to 2,813
lines; the extracted owner is 25 lines.

Next candidate:
Return to remaining review-package or row dispatch after strategy-review
orchestration has one production owner.

Blocked:
No.
