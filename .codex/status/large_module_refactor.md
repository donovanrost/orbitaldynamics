# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
OperationalReadiness operator-review gate extraction.

Status:
Selected; implementation not started.

Selected boundary:
Extract operator-review readiness gate precedence into
`OrbitalDynamics.OperationalReadiness.OperatorReviewGate`.
Preserve all OperationalReadiness and root public facades.

Selection evidence:
- Excluding the generated/declarative candidate-refresh JSON-schema module,
  live re-ranking places `operational_readiness.ex` at 1,338 lines, the
  largest ordinary eligible facade.
- OperationalReadiness delegates seventeen focused responsibilities, while the
  operator-review gate decision remains inline at lines 1,015-1,058.
- The selected code has one responsibility: classify blocked, review-required,
  review-present, import-handoff, or absent operator-review evidence.
- Evidence collection, all other gate decisions, report/summary projection, and
  all public contracts remain outside the boundary.
- Exact decision precedence, status/classification/reason strings, context
  omission, public output, and error behavior must remain unchanged.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
OperationalReadiness adapter-boundary gate extraction, selected in `008a5771`
and implemented in `dd724eb4`.
`operational_readiness.ex` moved from 1,388 to 1,338 lines; the dedicated
AdapterBoundaryGate owner is 61 lines.

Next candidate:
After this slice, re-rank the live checkout. RecommendationRiskContext is the
next largest ordinary eligible facade.

Blocked:
No.
