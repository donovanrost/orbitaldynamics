# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
RecommendationRiskContext timeline-dependency-impact extraction.

Status:
Completed and pushed in `5a38cbb3`.

Selected boundary:
Extract timeline-dependency-impact context keys, risk selection, and context
projection into
`OrbitalDynamics.RecommendationRiskContext.TimelineDependencyImpact`.
Preserve all RecommendationRiskContext and downstream public facades.

Selection evidence:
- Excluding the generated/declarative candidate-refresh JSON-schema module,
  live re-ranking places `recommendation_risk_context.ex` at 963 lines, the
  largest ordinary eligible facade.
- RecommendationRiskContext delegates twenty-three focused risk families,
  while timeline-dependency-impact keys, selection, and projection remain
  inline.
- The selected code has one responsibility: identify dependency-impact risks
  by feedback scope or impact key and project dependency, exclusivity,
  operator-action, derivation, and provenance context.
- Contention, filters, timeline preservation, and all other risk families
  remain outside the boundary.
- Exact context key order, scope/key selection, atom-key normalization,
  multi-key/list flattening, nil omission, value ordering, non-list behavior,
  public output, and error behavior must remain unchanged.

Implementation:
- Added
  `OrbitalDynamics.RecommendationRiskContext.TimelineDependencyImpact` as the
  focused owner of the ordered key contract, type/scope selection, atom-key
  normalization, and dependency, exclusivity, operator-action, derivation, and
  provenance context projection.
- Preserved the public RecommendationRiskContext facade through delegates.
- All other risk families remain outside the extraction.
- `recommendation_risk_context.ex` moved from 963 to 878 lines; the dedicated
  TimelineDependencyImpact owner is 124 lines.

Verification:
- Focused baseline and post-change test passed normally; the file retains its
  two pre-existing signed-zero warnings.
- Exact old/new public parity: four results passed, covering ordered keys,
  both selectors, atom-key normalization, all dependency/exclusivity list
  fields, nil omission, unrelated-risk exclusion, empty input, and non-list
  input.
- Five adjacent recommendation tests passed with warnings treated as errors.
- Static ownership and xref checks passed; only the facade calls the extracted
  owner at runtime.
- Forced warning-clean test compile passed across 4,040 files.
- Focused formatting and `git diff --check` passed.

Behavior/schema changes:
None intended.

Last completed slice:
RecommendationRiskContext timeline-dependency-impact extraction, selected in
`449fbfe3` and implemented in `5a38cbb3`.
`recommendation_risk_context.ex` moved from 963 to 878 lines; the dedicated
TimelineDependencyImpact owner is 124 lines.

Next candidate:
After this slice, re-rank the live checkout. OperationalReadiness is the next
largest ordinary eligible facade.

Blocked:
No.
