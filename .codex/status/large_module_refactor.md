# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
RecommendationRiskContext provider-reservation-request extraction.

Status:
Completed and pushed in `58692eff`.

Selected boundary:
Extract provider-reservation-request context keys, risk selection, and context
projection into
`OrbitalDynamics.RecommendationRiskContext.ProviderReservationRequest`.
Preserve all RecommendationRiskContext and downstream public facades.

Selection evidence:
- Excluding the generated/declarative candidate-refresh JSON-schema module,
  live re-ranking places `recommendation_risk_context.ex` at 1,033 lines, the
  largest ordinary eligible facade.
- RecommendationRiskContext delegates twenty-two focused risk families, while
  provider-reservation-request keys, selection, and projection remain inline.
- The selected code has one responsibility: identify provider reservation
  requests by feedback scope or request key and project contact, station,
  reservation, review, assumption, and provenance context.
- Contention, filters, timelines, and all other risk families remain outside
  the boundary.
- Exact context key order, scope/key selection, atom-key normalization,
  multi-key/list flattening, nil omission, value ordering, non-list behavior,
  public output, and error behavior must remain unchanged.

Implementation:
- Added
  `OrbitalDynamics.RecommendationRiskContext.ProviderReservationRequest` as the
  focused owner of the ordered key contract, scope/type selection, atom-key
  normalization, and reservation-request context projection.
- Preserved the public RecommendationRiskContext facade through delegates.
- All other risk families remain outside the extraction.
- `recommendation_risk_context.ex` moved from 1,033 to 963 lines; the dedicated
  ProviderReservationRequest owner is 109 lines.

Verification:
- Focused baseline and post-change test passed normally; the file retains its
  two pre-existing signed-zero warnings.
- Exact old/new public parity: four results passed, covering ordered keys,
  both selectors, atom-key normalization, multi-key/list flattening,
  assumption maps, unrelated-risk exclusion, empty input, and non-list input.
- Five adjacent recommendation tests passed with warnings treated as errors.
- Static ownership and xref checks passed; only the facade calls the extracted
  owner at runtime.
- Forced warning-clean test compile passed across 4,039 files.
- Focused formatting and `git diff --check` passed.

Behavior/schema changes:
None intended.

Last completed slice:
RecommendationRiskContext provider-reservation-request extraction, selected
in `4e897f13` and implemented in `58692eff`.
`recommendation_risk_context.ex` moved from 1,033 to 963 lines; the dedicated
ProviderReservationRequest owner is 109 lines.

Next candidate:
After this slice, re-rank the live checkout. OperationalReadiness is the next
largest ordinary eligible facade.

Blocked:
No.
