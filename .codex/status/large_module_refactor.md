# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
OperationalReadiness Cadence-import gate extraction.

Status:
Selected; implementation not started.

Selected boundary:
Extract Cadence-import readiness gate precedence and evidence-context projection
into `OrbitalDynamics.OperationalReadiness.CadenceImportGate`.
Preserve all OperationalReadiness and root public facades.

Selection evidence:
- Excluding the generated/declarative candidate-refresh JSON-schema module,
  live re-ranking places `operational_readiness.ex` at 1,474 lines, the
  largest ordinary eligible facade.
- OperationalReadiness delegates fifteen focused responsibilities, while the
  Cadence-import gate decision and context remain inline at lines 1,108-1,190.
- The selected code has one responsibility: classify import readiness from
  blocked/invalid, schema-validation, preparation, freshness, and ready-row
  evidence and project the supporting context.
- Evidence collection, all other gate decisions, report/summary projection, and
  all public contracts remain outside the boundary.
- Exact decision precedence, status/classification/reason strings, positive
  count filtering, timeline-publication context, public output, and error
  behavior must remain unchanged.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
RecommendationRiskContext score-term extraction, selected in `3d2248a4` and
implemented in `1a4cf909`.
`recommendation_risk_context.ex` moved from 1,527 to 1,405 lines; the dedicated
ScoreTerm owner is 156 lines.

Next candidate:
After this slice, re-rank the live checkout. RecommendationRiskContext is the
next largest ordinary eligible facade.

Blocked:
No.
