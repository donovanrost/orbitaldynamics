# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
OperationalReadiness source-contract gate extraction.

Status:
Selected; implementation not started.

Selected boundary:
Extract source-contract gate classification into
`OrbitalDynamics.OperationalReadiness.SourceContractGate`. Preserve all
OperationalReadiness and downstream public facades.

Selection evidence:
- Excluding the generated/declarative candidate-refresh JSON-schema module,
  live re-ranking places `operational_readiness.ex` at 1,187 lines, the
  largest ordinary eligible facade.
- OperationalReadiness delegates eight focused gate/decision owners, while the
  source-contract gate remains inline at lines 868-885.
- The selected code has one responsibility: classify missing inferred source
  artifact type as blocked and a declared type as importable.
- Source identity inference, evidence construction, operational mode, and all
  other gates remain outside the boundary.
- Exact nil/non-nil branching, gate status/classification/reason strings,
  public output, and error behavior must remain unchanged.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
RecommendationRiskContext approval-boundary extraction, selected in
`0175af8b` and implemented in `c443180c`.
`recommendation_risk_context.ex` moved from 1,212 to 1,153 lines; the dedicated
ApprovalBoundary owner is 83 lines.

Next candidate:
After this slice, re-rank the live checkout. OperationalReadiness and
RecommendationRiskContext are the next ordinary eligible facades.

Blocked:
No.
