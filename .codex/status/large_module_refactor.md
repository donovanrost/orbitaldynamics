# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
RecommendationRiskContext contact-contention extraction.

Status:
Completed and pushed in `2a6c16f2`.

Selected boundary:
Extract contact-contention context keys, risk classification, and context
projection into `OrbitalDynamics.RecommendationRiskContext.ContactContention`.
Preserve all RecommendationRiskContext and downstream public facades.

Selection evidence:
- Excluding the generated/declarative candidate-refresh JSON-schema module,
  live re-ranking places `recommendation_risk_context.ex` at 782 lines, the
  largest ordinary eligible facade.
- RecommendationRiskContext delegates twenty-five focused risk families, while
  contact-contention keys, classification, and projection remain inline.
- The selected code has one responsibility: identify contact-contention scope
  and project contact, scenario, station, demand, timing, contention,
  operator-action, derivation, and provenance context.
- Resolution selection, filters, timeline preservation, and all other risk
  families remain outside the boundary.
- Exact context key order, scope classification, atom-key normalization,
  multi-key/list flattening, nil omission, value ordering, non-list behavior,
  public output, and error behavior must remain unchanged.

Implementation:
- Added `OrbitalDynamics.RecommendationRiskContext.ContactContention` as the
  focused owner of the ordered key contract, scope classification, atom-key
  normalization, and contact, scenario, station, demand, timing, contention,
  operator-action, derivation, and provenance projection.
- Preserved the public RecommendationRiskContext facade through delegates.
- Resolution selection and all other risk families remain outside the
  extraction.
- `recommendation_risk_context.ex` moved from 782 to 683 lines; the dedicated
  ContactContention owner is 133 lines.

Verification:
- Focused baseline and post-change test passed normally; the file retains its
  two pre-existing signed-zero warnings.
- Exact old/new public parity: four results passed, covering ordered keys,
  scope classification, atom-key normalization, type/risk_type value
  preservation, all multi-key/list fields, nil omission, unrelated-risk
  exclusion, empty input, and non-list input.
- Five adjacent recommendation tests passed with warnings treated as errors.
- Static ownership and xref checks passed; only the facade calls the extracted
  owner at runtime.
- Forced warning-clean test compile passed across 4,044 files.
- Focused formatting and `git diff --check` passed.

Behavior/schema changes:
None intended.

Last completed slice:
RecommendationRiskContext contact-contention extraction, selected in
`88af42be` and implemented in `2a6c16f2`.
`recommendation_risk_context.ex` moved from 782 to 683 lines; the dedicated
ContactContention owner is 133 lines.

Next candidate:
After this slice, re-rank the live checkout. OperationalReadiness is the next
largest ordinary eligible facade.

Blocked:
No.
