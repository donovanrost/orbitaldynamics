# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
RecommendationRiskContext timeline-integrity extraction.

Status:
Completed and pushed in `2a89f3dd`.

Selected boundary:
Extract timeline-integrity context keys, risk classification, and context
projection into `OrbitalDynamics.RecommendationRiskContext.TimelineIntegrity`.
Preserve all RecommendationRiskContext and downstream public facades.

Selection evidence:
- Excluding the generated/declarative candidate-refresh JSON-schema module,
  live re-ranking places `recommendation_risk_context.ex` at 1,304 lines, the
  largest ordinary eligible facade.
- RecommendationRiskContext delegates eighteen focused risk families, while
  timeline-integrity keys, projection, and classification remain inline at
  lines 355-378, 439, 1,170-1,230, and 1,236-1,242.
- The selected code has one responsibility: identify timeline-integrity risks
  and project stable dependency, exclusivity, review, and provenance context.
- Contact/resource filters, objective/score/resource-margin context, and all
  other risk families remain outside the boundary.
- Exact context keys and order, type/risk_type/feedback_scope classification,
  atom-key normalization, list flattening, nil omission, value ordering,
  non-list behavior, public output, and error behavior must remain unchanged.

Implementation:
- Added `OrbitalDynamics.RecommendationRiskContext.TimelineIntegrity` as the
  focused owner of the ordered context keys, type/risk_type/feedback_scope
  classifiers, atom-key normalization, and dependency, exclusivity, review,
  and provenance context projection.
- Preserved the public RecommendationRiskContext facade through delegates.
- Other risk families remain outside the extraction.
- `recommendation_risk_context.ex` moved from 1,304 to 1,212 lines; the
  dedicated TimelineIntegrity owner is 124 lines.

Verification:
- Strict focused baseline: one test passed normally; the file retains its two
  pre-existing signed-zero warnings.
- Exact old/new public parity: four fixtures passed, covering ordered keys,
  rich atom-keyed context, all three accepted classifiers, and non-list input.
- Post-change focused and adjacent checks: three selected tests passed; both
  adjacent tests passed with warnings treated as errors.
- Static ownership and xref checks passed; only the facade calls the extracted
  owner at runtime.
- Forced warning-clean test compile passed across 4,028 files.
- Focused formatting and `git diff --check` passed.

Behavior/schema changes:
None intended.

Last completed slice:
RecommendationRiskContext timeline-integrity extraction, selected in
`25379834` and implemented in `2a89f3dd`.
`recommendation_risk_context.ex` moved from 1,304 to 1,212 lines; the dedicated
TimelineIntegrity owner is 124 lines.

Next candidate:
After this slice, re-rank the live checkout. OperationalReadiness is the next
largest ordinary eligible facade.

Blocked:
No.
