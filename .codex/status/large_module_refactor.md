# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
OperationalReadiness unavailable-resource summary extraction.

Status:
Selected; implementation not started.

Selected boundary:
Extract unavailable-resource quality-gate summary construction and its
row-aggregation helpers into
`OrbitalDynamics.OperationalReadiness.QualityGateUnavailableResourceSummary`.
Preserve all OperationalReadiness and downstream public facades.

Selection evidence:
- Excluding the generated/declarative candidate-refresh JSON-schema module,
  live re-ranking places `operational_readiness.ex` at 1,063 lines, the
  largest ordinary eligible facade.
- Operator-training, schema-validation, import-readiness, and general quality
  summaries already have focused owners, while unavailable-resource summary
  construction and its row aggregation remain inline.
- The selected code has one responsibility: aggregate resource-availability
  rows into reason, station, blocking, contact, status, and routing summaries.
- Quality-gate report construction, row projection, readiness evidence
  construction, and all gates remain outside the boundary.
- Exact artifact fields, positive-count filtering, reason classification,
  stable ID normalization, count merging, status routing, assumptions,
  model limits, nil compaction, public output, and error behavior must remain
  unchanged.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
RecommendationRiskContext station-reservation-conflict extraction, selected
in `f6094848` and implemented in `b36d6c11`.
`recommendation_risk_context.ex` moved from 1,094 to 1,033 lines; the dedicated
StationReservationConflict owner is 100 lines.

Next candidate:
After this slice, re-rank the live checkout. RecommendationRiskContext is the
next largest ordinary eligible facade.

Blocked:
No.
