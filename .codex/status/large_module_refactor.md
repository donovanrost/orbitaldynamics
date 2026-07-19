# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport constraint/objective assessment import extraction.

Status:
Selected; implementation has not started.

Selected boundary:
Extract the constraint-report and objective-satisfaction constructor
implementations into
`OrbitalDynamics.CadenceImport.ConstraintObjectiveImport`. Preserve both public
facade entry points and pass the existing review-package import seam as a
callback.

Selection evidence:
- `cadence_import.ex` is now 2,384 lines.
- The selected contiguous pair spans about 35 lines and owns assessment
  normalization, source-identity, OperatorReview conversion, and source
  contracts.
- The pair has one responsibility: turn constraint and objective-satisfaction
  evidence into review-package imports while preserving the constraint
  assumptions-source fallback.
- Public API docs, row construction, manifest assembly, schemas, and adjacent
  candidate/maneuver/resource-projection imports remain outside the boundary.

Verification:
Pending: focused assessment baselines, exact old/new constructor equivalence
proof, strict compile, all combined CadenceImport tests, schema contracts,
static single ownership, runtime xref, and bounded review.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
CadenceImport maneuver import extraction, selected in `c89cd4aa` and
implemented in `66a19fe0`. `cadence_import.ex` moved from 2,411 to 2,384 lines;
the extracted owner is 57 lines.

Next candidate:
Re-inventory remaining public routing after constraint/objective imports have
one production owner.

Blocked:
No.
