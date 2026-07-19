# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport strategy-decision import extraction.

Status:
Completed and published.

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
- Strict test compile passed with 3,829 files and warnings as errors.
- Five representative strategy-decision tests passed with 67 excluded.
- All combined CadenceImport tests passed: 96 tests.
- CadenceImport schema contracts passed: 4 tests.
- An executable before/after proof matched 42 cases across all seven
  constructors, three key/source-ID shapes, and inferred versus explicit IDs.
- Formatting and diff checks passed, and no temporary proof files remain.
- Static ownership checks confirmed all seven public facade entry points
  delegate to one implementation owner.
- Runtime xref confirmed `cadence_import.ex` is the direct consumer of
  `strategy_decision_import.ex`.
- Bounded local review found no normalization, source-ID precedence or
  fallback, OperatorReview conversion, source-contract, public API, row,
  ordering, or schema changes.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
CadenceImport strategy-decision import extraction, selected in `89b81749` and
implemented in `3203c852`. `cadence_import.ex` moved from 2,523 to 2,472 lines;
the extracted owner is 112 lines.

Next candidate:
Re-inventory remaining public routing after strategy-decision imports have one
production owner.

Blocked:
No.
