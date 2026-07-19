# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport maneuver import extraction.

Status:
Selected; implementation has not started.

Selected boundary:
Extract the three maneuver recommendation, execution-delta, and review-report
constructor implementations into
`OrbitalDynamics.CadenceImport.ManeuverReviewImport`. Preserve every public
facade entry point and pass the existing review-package import seam as a
callback.

Selection evidence:
- `cadence_import.ex` is now 2,411 lines.
- The selected contiguous family spans about 55 lines and owns the three
  maneuver-specific normalization, source-identity, OperatorReview conversion,
  and source-contract paths.
- The family has one responsibility: turn maneuver evidence into
  review-package imports while preserving each artifact's distinct ID
  precedence.
- Public API docs, row construction, manifest assembly, schemas, and adjacent
  constraint/objective imports remain outside the boundary.

Verification:
Pending: focused maneuver baselines, exact old/new constructor equivalence
proof, strict compile, all combined CadenceImport tests, schema contracts,
static single ownership, runtime xref, and bounded review.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
CadenceImport candidate-evaluation import extraction, selected in `179a6333`
and implemented in `e1dabcb5`. `cadence_import.ex` moved from 2,472 to 2,411
lines; the extracted owner is 122 lines.

Next candidate:
Re-inventory remaining public routing after maneuver imports have one
production owner.

Blocked:
No.
