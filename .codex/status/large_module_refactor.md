# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
RecommendationRiskContext station-reservation-conflict extraction.

Status:
Selected; implementation not started.

Selected boundary:
Extract station-reservation-conflict context keys, risk selection, and context
projection into
`OrbitalDynamics.RecommendationRiskContext.StationReservationConflict`.
Preserve all RecommendationRiskContext and downstream public facades.

Selection evidence:
- Excluding the generated/declarative candidate-refresh JSON-schema module,
  live re-ranking places `recommendation_risk_context.ex` at 1,094 lines, the
  largest ordinary eligible facade.
- RecommendationRiskContext delegates twenty-one focused risk families, while
  station-reservation-conflict keys, risk selection, and projection remain
  inline.
- The selected code has one responsibility: identify reservation conflicts by
  feedback scope or conflict key and project contact, station, reservation,
  status, expiry, derivation, and provenance context.
- Provider reservations, contention, filters, timelines, and all other risk
  families remain outside the boundary.
- Exact context key order, scope/key selection, atom-key normalization, list
  flattening, nil omission, value ordering, non-list behavior, public output,
  and error behavior must remain unchanged.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
OperationalReadiness quality-gate row extraction, selected in `15bafb68` and
implemented in `267f9eeb`.
`operational_readiness.ex` moved from 1,140 to 1,063 lines; the dedicated
QualityGateRow owner is 124 lines.

Next candidate:
After this slice, re-rank the live checkout. OperationalReadiness is the next
largest ordinary eligible facade.

Blocked:
No.
