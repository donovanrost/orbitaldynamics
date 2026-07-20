# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
OperationalReadiness resource-availability gate extraction.

Status:
Selected; implementation not started.

Selected boundary:
Extract resource-availability gate classification and context projection into
`OrbitalDynamics.OperationalReadiness.ResourceAvailabilityGate`. Preserve all
OperationalReadiness and downstream public facades.

Selection evidence:
- Excluding the generated/declarative candidate-refresh JSON-schema module,
  live re-ranking places `operational_readiness.ex` at 1,295 lines, the
  largest ordinary eligible facade.
- OperationalReadiness delegates five focused gate/decision owners, while the
  resource-availability gate and its context remain inline at lines 973-1,014.
- The selected code has one responsibility: classify declared resource
  pressure and project stable reason, station, blocking, provenance, and trust
  context into the resource-availability gate.
- Quality-gate row helpers, evidence construction, mission policy, operator
  training, and all other gates remain outside the boundary.
- Exact gate inclusion, status/classification/reason strings, map keys and
  values, positive-count filtering, sorted reason IDs, station/unavailable
  reason classification, public output, and error behavior must remain
  unchanged.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
RecommendationRiskContext timeline-integrity extraction, selected in
`25379834` and implemented in `2a89f3dd`.
`recommendation_risk_context.ex` moved from 1,304 to 1,212 lines; the dedicated
TimelineIntegrity owner is 124 lines.

Next candidate:
After this slice, re-rank the live checkout. RecommendationRiskContext is the
next largest ordinary eligible facade.

Blocked:
No.
