# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
OperationalReadiness adapter-boundary gate extraction.

Status:
Selected; implementation not started.

Selected boundary:
Extract adapter trust-boundary gate precedence and evidence-context projection
into `OrbitalDynamics.OperationalReadiness.AdapterBoundaryGate`.
Preserve all OperationalReadiness and root public facades.

Selection evidence:
- Excluding the generated/declarative candidate-refresh JSON-schema module,
  live re-ranking places `operational_readiness.ex` at 1,388 lines, the
  largest ordinary eligible facade.
- OperationalReadiness delegates sixteen focused responsibilities, while the
  adapter-boundary gate decision and context remain inline at lines 902-951.
- The selected code has one responsibility: classify untrusted, missing,
  declared, or absent adapter trust-boundary evidence.
- Evidence collection, all other gate decisions, report/summary projection, and
  all public contracts remain outside the boundary.
- Exact decision precedence, status/classification/reason strings, context
  fields and omission, public output, and error behavior must remain unchanged.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
RecommendationRiskContext resource-margin extraction, selected in `abd70a00`
and implemented in `015526be`.
`recommendation_risk_context.ex` moved from 1,405 to 1,304 lines; the dedicated
ResourceMargin owner is 136 lines.

Next candidate:
After this slice, re-rank the live checkout. RecommendationRiskContext is the
next largest ordinary eligible facade.

Blocked:
No.
