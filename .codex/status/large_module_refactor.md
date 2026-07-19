# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport candidate-evaluation import extraction.

Status:
Selected; implementation has not started.

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
Pending: representative focused candidate-evaluation baselines, exact old/new
constructor equivalence proof, strict compile, all combined CadenceImport
tests, schema contracts, static single ownership, runtime xref, and bounded
review.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
CadenceImport strategy-decision import extraction, selected in `89b81749` and
implemented in `3203c852`. `cadence_import.ex` moved from 2,523 to 2,472 lines;
the extracted owner is 112 lines.

Next candidate:
Re-inventory remaining public routing after candidate-evaluation imports have
one production owner.

Blocked:
No.
