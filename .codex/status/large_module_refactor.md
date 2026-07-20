# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
OperationalReadiness readiness-report assembly extraction.

Status:
Selected; implementation not started.

Selected boundary:
Extract readiness gate assembly, classification, and report projection into
`OrbitalDynamics.OperationalReadiness.ReadinessReport`. Preserve all
OperationalReadiness and downstream public facades.

Selection evidence:
- Excluding the generated/declarative candidate-refresh JSON-schema module,
  live re-ranking places `operational_readiness.ex` at 827 lines, the
  largest ordinary eligible facade.
- All individual readiness gates, source identity, and quality reporting have
  focused owners, while gate-list assembly, classification, and readiness
  report projection remain inline.
- The selected code has one responsibility: combine source identity, normalized
  evidence, gate builders, classification precedence, counts, assumptions, and
  model limits into the readiness report.
- Review/import source acquisition and evidence construction remain outside
  the boundary.
- Exact gate order and omission, classification precedence, report ID inputs,
  status/count derivation, assumptions, model limits, public output, and error
  behavior must remain unchanged.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
RecommendationRiskContext link-capacity extraction, selected in `42b96465`
and implemented in `ee7312e9`.
`recommendation_risk_context.ex` moved from 878 to 782 lines; the dedicated
LinkCapacity owner is 128 lines.

Next candidate:
After this slice, re-rank the live checkout. RecommendationRiskContext is the
next largest ordinary eligible facade.

Blocked:
No.
