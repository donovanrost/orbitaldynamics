# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
RecommendationRiskContext capacity-pack extraction.

Status:
Completed and pushed in `bdc570d2`.

Selected boundary:
Extract capacity-pack context keys, risk selection, and context projection into
`OrbitalDynamics.RecommendationRiskContext.CapacityPack`. Preserve all
RecommendationRiskContext and downstream public facades.

Selection evidence:
- Excluding the generated/declarative candidate-refresh JSON-schema module,
  live re-ranking places `recommendation_risk_context.ex` at 1,153 lines, the
  largest ordinary eligible facade.
- RecommendationRiskContext delegates twenty focused risk families, while
  capacity-pack keys, scope selection, and projection remain inline at lines
  45-60, 346, and 469-512.
- The selected code has one responsibility: identify capacity-pack risk
  context and project contact, station, capacity, derivation, and provenance
  fields.
- Provider reservations, contention, filters, timelines, and all other risk
  families remain outside the boundary.
- Exact context key order, scope selection, atom-key normalization, list
  flattening, nil omission, value ordering, non-list behavior, public output,
  and error behavior must remain unchanged.

Implementation:
- Added `OrbitalDynamics.RecommendationRiskContext.CapacityPack` as the focused
  owner of the ordered key contract, scope/group risk selection, atom-key
  normalization, and contact, station, capacity, derivation, and provenance
  context projection.
- Preserved the public RecommendationRiskContext facade through delegates.
- All other risk families remain outside the extraction.
- `recommendation_risk_context.ex` moved from 1,153 to 1,094 lines; the
  dedicated CapacityPack owner is 96 lines.

Verification:
- Focused baseline and post-change test passed normally; the file retains its
  two pre-existing signed-zero warnings.
- Exact old/new public parity: four results passed, covering ordered keys,
  both selection forms, atom-key normalization, multi-key/list flattening,
  nil omission, unrelated-risk exclusion, empty input, and non-list input.
- Five adjacent recommendation tests passed with warnings treated as errors.
- Static ownership and xref checks passed; only the facade calls the extracted
  owner at runtime.
- Forced warning-clean test compile passed across 4,035 files.
- Focused formatting and `git diff --check` passed.

Behavior/schema changes:
None intended.

Last completed slice:
RecommendationRiskContext capacity-pack extraction, selected in `aee20d5b`
and implemented in `bdc570d2`.
`recommendation_risk_context.ex` moved from 1,153 to 1,094 lines; the dedicated
CapacityPack owner is 96 lines.

Next candidate:
After this slice, re-rank the live checkout. OperationalReadiness is the next
largest ordinary eligible facade.

Blocked:
No.
