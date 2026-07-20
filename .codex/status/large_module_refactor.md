# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
OperationalReadiness operator-training gate extraction.

Status:
Selected; implementation not started.

Selected boundary:
Extract operator-training gate classification and context projection into
`OrbitalDynamics.OperationalReadiness.OperatorTrainingGate`. Preserve all
OperationalReadiness and downstream public facades.

Selection evidence:
- Excluding the generated/declarative candidate-refresh JSON-schema module,
  live re-ranking places `operational_readiness.ex` at 1,213 lines, the
  largest ordinary eligible facade.
- OperationalReadiness delegates seven focused gate/decision owners, while the
  operator-training gate and its context remain inline at lines 906-931.
- The selected code has one responsibility: include a review-required gate
  when declared training/qualification evidence exists and project its
  requirement, role, training, certification, and qualification context.
- Training evidence construction, quality-gate row helpers, and all other
  gates remain outside the boundary.
- Exact gate inclusion, integer-positive guard, status/classification/reason
  strings, context keys and values, public output, and error behavior must
  remain unchanged.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
OperationalReadiness mission-policy gate extraction, selected in `9f79d849`
and implemented in `4889e702`.
`operational_readiness.ex` moved from 1,253 to 1,213 lines; the dedicated
MissionPolicyGate owner is 51 lines.

Next candidate:
After this slice, re-rank the live checkout. RecommendationRiskContext is the
next largest ordinary eligible facade.

Blocked:
No.
