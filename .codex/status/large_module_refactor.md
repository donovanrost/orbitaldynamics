# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport strategy-decision import extraction.

Status:
Selected; implementation has not started.

Selected boundary:
Extract the seven approval-requirement, policy-decision, comparison, scoring,
tradeoff, and Pareto constructor implementations into
`OrbitalDynamics.CadenceImport.StrategyDecisionImport`. Preserve every public
facade entry point and pass the existing review-package import seam as a
callback.

Selection evidence:
- `cadence_import.ex` is now 2,523 lines.
- The selected contiguous family spans about 120 lines and repeats the same
  normalization, source-identity, OperatorReview conversion, and contract
  routing flow for seven strategy-decision artifact shapes.
- The family has one responsibility: turn decision evidence into review-package
  imports while preserving each artifact's identity fallback.
- Public API docs, row construction, manifest assembly, schemas, and
  validation/readiness imports remain outside the boundary.

Verification:
Pending: representative focused decision-import baselines, exact old/new
constructor equivalence proof, strict compile, all combined CadenceImport
tests, schema contracts, static single ownership, runtime xref, and bounded
review.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
CadenceImport validation and readiness import extraction, selected in
`31ee642d` and implemented in `ab7fd582`. `cadence_import.ex` moved from 2,573
to 2,523 lines; the extracted owner is 68 lines.

Next candidate:
Re-inventory remaining public routing after strategy-decision imports have one
production owner.

Blocked:
No.
