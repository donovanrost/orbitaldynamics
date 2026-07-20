# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
RecommendationRiskContext capacity-pack extraction.

Status:
Selected; implementation not started.

Selected boundary:
Extract capacity-pack context keys, risk selection, and context projection into
`OrbitalDynamics.RecommendationRiskContext.CapacityPack`. Preserve all
RecommendationRiskContext and downstream public facades.

Selection evidence:
- Excluding the generated/declarative candidate-refresh JSON-schema module,
  live re-ranking places `recommendation_risk_context.ex` at 1,153 lines, the
  largest ordinary eligible facade.
- RecommendationRiskContext delegates twenty focused risk families, while
  capacity-pack keys, scope selection, and projection remain inline at lines
  45-60, 346, and 469-512.
- The selected code has one responsibility: identify capacity-pack risk
  context and project contact, station, capacity, derivation, and provenance
  fields.
- Provider reservations, contention, filters, timelines, and all other risk
  families remain outside the boundary.
- Exact context key order, scope selection, atom-key normalization, list
  flattening, nil omission, value ordering, non-list behavior, public output,
  and error behavior must remain unchanged.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
OperationalReadiness operational-mode gate extraction, selected in `5cb32e19`
and implemented in `054a74b0`.
`operational_readiness.ex` moved from 1,170 to 1,140 lines; the dedicated
OperationalModeGate owner is 28 lines.

Next candidate:
After this slice, re-rank the live checkout. OperationalReadiness is the next
largest ordinary eligible facade.

Blocked:
No.
