# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
OperationalReadiness evidence-construction extraction.

Status:
Selected; implementation not started.

Selected boundary:
Extract normalized readiness evidence construction and its private aggregation
delegates into `OrbitalDynamics.OperationalReadiness.ReadinessEvidence`.
Preserve all OperationalReadiness and downstream public facades.

Selection evidence:
- Excluding the generated/declarative candidate-refresh JSON-schema module,
  live re-ranking places `operational_readiness.ex` at 765 lines, the
  largest ordinary eligible facade.
- Readiness report assembly, all gate builders, and specialized evidence
  normalizers already have focused owners, while evidence orchestration and
  aggregation remain inline.
- The selected code has one responsibility: combine review/import rows and
  normalized freshness, validation, source-model, policy, adapter, training,
  resource, and timeline-publication evidence into the stable evidence map.
- Review/import source acquisition, readiness report assembly, and all public
  routing remain outside the boundary.
- Exact row-source precedence, count derivation, reason classification, stable
  ID maps, evidence keys and values, timeline context merge, public output, and
  error behavior must remain unchanged.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
RecommendationRiskContext contact-contention extraction, selected in
`88af42be` and implemented in `2a6c16f2`.
`recommendation_risk_context.ex` moved from 782 to 683 lines; the dedicated
ContactContention owner is 133 lines.

Next candidate:
After this slice, re-rank the live checkout. RecommendationRiskContext is the
next largest ordinary eligible facade.

Blocked:
No.
