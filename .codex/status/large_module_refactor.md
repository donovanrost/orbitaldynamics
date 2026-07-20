# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
RecommendationRiskContext relay-data-path extraction.

Status:
Selected; strict focused baseline pending.

Selected boundary:
Extract relay-data-path context key ownership, risk selection, normalization,
and context projection into
`OrbitalDynamics.RecommendationRiskContext.RelayDataPath`.
Preserve all RecommendationRiskContext and root public facades.

Selection evidence:
- Excluding the generated/declarative candidate-refresh JSON-schema module,
  live re-ranking places `recommendation_risk_context.ex` at 1,772 lines, the
  largest ordinary eligible facade.
- RecommendationRiskContext already delegates fourteen focused risk families,
  while relay-data-path keys and projection remain inline at lines 265-298,
  1,077-1,159, and 1,702-1,706.
- The selected block has one responsibility: project relay route, custody,
  latency, routing-count, feedback, trust, and assumption evidence from matching
  risks.
- All other risk families, shared public facades, and downstream strategy
  assembly remain outside the boundary.
- Exact shallow key normalization, risk matching, key aliases, list flattening,
  uniqueness, empty omission, output keys, public output, and non-list behavior
  must remain unchanged.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
ContactIntent summary projection extraction, selected in `d7dbf991` and
implemented in `f9d3fd44`.
`communications/contact_intent.ex` moved from 1,785 to 1,529 lines; the
dedicated Summary owner is 285 lines.

Next candidate:
Re-rank the live checkout and select the next bounded facade-preserving
extraction. `recommendation_risk_context.ex` is now the largest ordinary
eligible facade at 1,772 lines, followed by OperationalReadiness and
ContactAllocation.

Blocked:
No.
