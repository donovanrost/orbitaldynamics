# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
OperationalReadiness operational-mode gate extraction.

Status:
Selected; implementation not started.

Selected boundary:
Extract operational-mode gate construction into
`OrbitalDynamics.OperationalReadiness.OperationalModeGate`. Preserve all
OperationalReadiness and downstream public facades.

Selection evidence:
- Excluding the generated/declarative candidate-refresh JSON-schema module,
  live re-ranking places `operational_readiness.ex` at 1,170 lines, the
  largest ordinary eligible facade.
- OperationalReadiness delegates nine focused gate/decision owners, while the
  operational-mode decision-to-gate adapter remains inline at lines 869-889.
- The selected code has one responsibility: turn an absent mode decision into
  a passed gate or a declared mode decision into an analysis-only gate with
  stable source and reason context.
- OperationalModeDecision semantics, evidence construction, and all other
  gates remain outside the boundary.
- Exact decision call, nil/tuple branching, gate status/classification/reason
  strings, context keys and values, public output, and error behavior must
  remain unchanged.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
OperationalReadiness source-contract gate extraction, selected in `d8254a8b`
and implemented in `9ab3aa44`.
`operational_readiness.ex` moved from 1,187 to 1,170 lines; the dedicated
SourceContractGate owner is 28 lines.

Next candidate:
After this slice, re-rank the live checkout. RecommendationRiskContext is the
next largest ordinary eligible facade.

Blocked:
No.
