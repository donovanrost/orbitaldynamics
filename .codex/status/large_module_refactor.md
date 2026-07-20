# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
OperationalReadiness mission-policy gate extraction.

Status:
Selected; implementation not started.

Selected boundary:
Extract mission-policy gate classification and context projection into
`OrbitalDynamics.OperationalReadiness.MissionPolicyGate`. Preserve all
OperationalReadiness and downstream public facades.

Selection evidence:
- Excluding the generated/declarative candidate-refresh JSON-schema module,
  live re-ranking places `operational_readiness.ex` at 1,253 lines, the
  largest ordinary eligible facade.
- OperationalReadiness delegates six focused gate/decision owners, while the
  mission-policy gate and its context remain inline at lines 906-944.
- The selected code has one responsibility: classify declared mission-policy
  evidence as blocked, review-required, importable, or absent and project its
  decision count and classification counts.
- Evidence construction, quality-gate helpers, operator training, and all
  other gates remain outside the boundary.
- Exact branch precedence, gate inclusion, status/classification/reason
  strings, context keys and values, public output, and error behavior must
  remain unchanged.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
OperationalReadiness resource-availability gate extraction, selected in
`60ee070b` and implemented in `a0fccffa`.
`operational_readiness.ex` moved from 1,295 to 1,253 lines; the dedicated
ResourceAvailabilityGate owner is 84 lines.

Next candidate:
After this slice, re-rank the live checkout. RecommendationRiskContext and
OperationalReadiness are the next ordinary eligible facades.

Blocked:
No.
