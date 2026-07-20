# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
OperationalReadiness quality-gate row extraction.

Status:
Selected; implementation not started.

Selected boundary:
Extract quality-gate row identity, base projection, gate-specific context, and
compaction into `OrbitalDynamics.OperationalReadiness.QualityGateRow`.
Preserve all OperationalReadiness and downstream public facades.

Selection evidence:
- Excluding the generated/declarative candidate-refresh JSON-schema module,
  live re-ranking places `operational_readiness.ex` at 1,140 lines, the
  largest ordinary eligible facade.
- OperationalReadiness delegates all individual readiness gates and summary
  builders, while quality-gate row identity, base fields, gate-specific
  context, and compaction remain inline at lines 563-637.
- The selected code has one responsibility: project one readiness gate into
  one stable quality-gate row, including resource, Cadence import, adapter, and
  operator-training context.
- Report aggregation, unavailable-resource summary aggregation, readiness
  evidence construction, and all gates remain outside the boundary.
- Exact row ID inputs, field values, gate-specific dispatch, positive-count
  filtering, stable ID-array normalization, nil compaction, public output, and
  error behavior must remain unchanged.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
RecommendationRiskContext capacity-pack extraction, selected in `aee20d5b`
and implemented in `bdc570d2`.
`recommendation_risk_context.ex` moved from 1,153 to 1,094 lines; the dedicated
CapacityPack owner is 96 lines.

Next candidate:
After this slice, re-rank the live checkout. RecommendationRiskContext is the
next largest ordinary eligible facade.

Blocked:
No.
