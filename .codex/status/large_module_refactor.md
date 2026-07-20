# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
RecommendationRiskContext link-capacity extraction.

Status:
Completed and pushed in `ee7312e9`.

Selected boundary:
Extract link-capacity context keys, risk classification, and context projection
into `OrbitalDynamics.RecommendationRiskContext.LinkCapacity`. Preserve all
RecommendationRiskContext and downstream public facades.

Selection evidence:
- Excluding the generated/declarative candidate-refresh JSON-schema module,
  live re-ranking places `recommendation_risk_context.ex` at 878 lines, the
  largest ordinary eligible facade.
- RecommendationRiskContext delegates twenty-four focused risk families, while
  link-capacity keys, classification, and projection remain inline.
- The selected code has one responsibility: identify scoped downlink-gap and
  actual-link-capacity risks and project demand, completion, throughput,
  shortfall, status, derivation, and provenance context.
- Contention, filters, timeline preservation, and all other risk families
  remain outside the boundary.
- Exact context key order, classifier forms, atom-key normalization,
  multi-key/list flattening, nil omission, value ordering, non-list behavior,
  public output, and error behavior must remain unchanged.

Implementation:
- Added `OrbitalDynamics.RecommendationRiskContext.LinkCapacity` as the focused
  owner of the ordered key contract, scoped type/risk_type classification,
  atom-key normalization, and demand, completion, throughput, shortfall,
  status, derivation, and provenance projection.
- Preserved the public RecommendationRiskContext facade through delegates.
- All other risk families remain outside the extraction.
- `recommendation_risk_context.ex` moved from 878 to 782 lines; the dedicated
  LinkCapacity owner is 128 lines.

Verification:
- Focused baseline and post-change test passed normally; the file retains its
  two pre-existing signed-zero warnings.
- Exact old/new public parity: four results passed, covering ordered keys,
  both accepted classifiers, both rejection dimensions, atom-key
  normalization, multi-key/list flattening, nil omission, throughput/status
  fields, empty input, and non-list input.
- Five adjacent recommendation tests passed with warnings treated as errors.
- Static ownership and xref checks passed; only the facade calls the extracted
  owner at runtime.
- Forced warning-clean test compile passed across 4,042 files.
- Focused formatting and `git diff --check` passed.

Behavior/schema changes:
None intended.

Last completed slice:
RecommendationRiskContext link-capacity extraction, selected in `42b96465`
and implemented in `ee7312e9`.
`recommendation_risk_context.ex` moved from 878 to 782 lines; the dedicated
LinkCapacity owner is 128 lines.

Next candidate:
After this slice, re-rank the live checkout. OperationalReadiness is the next
largest ordinary eligible facade.

Blocked:
No.
