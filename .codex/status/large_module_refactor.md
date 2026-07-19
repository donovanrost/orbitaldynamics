# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport candidate-evaluation import extraction.

Status:
Completed and published.

Selected boundary:
Extract the eight contact/resource filtering, candidate diff/rejection,
provider counteroffer, invalidation, freshness, and refresh-budget constructor
implementations into `OrbitalDynamics.CadenceImport.CandidateEvaluationImport`.
Preserve every public facade entry point and pass the existing review-package
import seam as a callback.

Selection evidence:
- `cadence_import.ex` is now 2,472 lines.
- The selected contiguous family spans about 125 lines and repeats the same
  normalization, source-identity, OperatorReview conversion, and contract
  routing flow for eight candidate-evaluation artifact shapes.
- The family has one responsibility: turn candidate acceptance, suppression,
  validity, freshness, and budget evidence into review-package imports.
- Public API docs, row construction, manifest assembly, schemas, and adjacent
  resource projection/constraint imports remain outside the boundary.

Verification:
- Strict test compile passed with 3,830 files and warnings as errors.
- Five representative candidate-evaluation tests passed with 67 excluded.
- All combined CadenceImport tests passed: 96 tests.
- CadenceImport schema contracts passed: 4 tests.
- An executable before/after proof matched 48 cases across all eight
  constructors, three key/source-ID shapes, and inferred versus explicit IDs.
- Formatting and diff checks passed, and no temporary proof files remain.
- Static ownership checks confirmed all eight public facade entry points
  delegate to one implementation owner.
- Runtime xref confirmed `cadence_import.ex` is the direct consumer of
  `candidate_evaluation_import.ex`.
- Bounded local review found no normalization, source-ID precedence or
  fallback, OperatorReview conversion, source-contract, public API, row,
  ordering, or schema changes.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
CadenceImport candidate-evaluation import extraction, selected in `179a6333`
and implemented in `e1dabcb5`. `cadence_import.ex` moved from 2,472 to 2,411
lines; the extracted owner is 122 lines.

Next candidate:
Re-inventory remaining public routing after candidate-evaluation imports have
one production owner.

Blocked:
No.
