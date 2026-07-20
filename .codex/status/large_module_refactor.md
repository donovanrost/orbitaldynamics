# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
RecommendationRiskContext station-reservation-conflict extraction.

Status:
Completed and pushed in `b36d6c11`.

Selected boundary:
Extract station-reservation-conflict context keys, risk selection, and context
projection into
`OrbitalDynamics.RecommendationRiskContext.StationReservationConflict`.
Preserve all RecommendationRiskContext and downstream public facades.

Selection evidence:
- Excluding the generated/declarative candidate-refresh JSON-schema module,
  live re-ranking places `recommendation_risk_context.ex` at 1,094 lines, the
  largest ordinary eligible facade.
- RecommendationRiskContext delegates twenty-one focused risk families, while
  station-reservation-conflict keys, risk selection, and projection remain
  inline.
- The selected code has one responsibility: identify reservation conflicts by
  feedback scope or conflict key and project contact, station, reservation,
  status, expiry, derivation, and provenance context.
- Provider reservations, contention, filters, timelines, and all other risk
  families remain outside the boundary.
- Exact context key order, scope/key selection, atom-key normalization, list
  flattening, nil omission, value ordering, non-list behavior, public output,
  and error behavior must remain unchanged.

Implementation:
- Added
  `OrbitalDynamics.RecommendationRiskContext.StationReservationConflict` as the
  focused owner of the ordered key contract, required scope-plus-match-key
  selection, atom-key normalization, and reservation-conflict projection.
- Preserved the public RecommendationRiskContext facade through delegates.
- All other risk families remain outside the extraction.
- `recommendation_risk_context.ex` moved from 1,094 to 1,033 lines; the
  dedicated StationReservationConflict owner is 100 lines.

Verification:
- Focused baseline and post-change test passed normally; the file retains its
  two pre-existing signed-zero warnings.
- Exact old/new public parity: four results passed, covering ordered keys, the
  scope-plus-match-key selector, atom-key normalization, multi-key/list
  flattening, nil omission, partial-match exclusion, empty input, and non-list
  input.
- Five adjacent recommendation tests passed with warnings treated as errors.
- Static ownership and xref checks passed; only the facade calls the extracted
  owner at runtime.
- Forced warning-clean test compile passed across 4,037 files.
- Focused formatting and `git diff --check` passed.

Behavior/schema changes:
None intended.

Last completed slice:
RecommendationRiskContext station-reservation-conflict extraction, selected
in `f6094848` and implemented in `b36d6c11`.
`recommendation_risk_context.ex` moved from 1,094 to 1,033 lines; the dedicated
StationReservationConflict owner is 100 lines.

Next candidate:
After this slice, re-rank the live checkout. OperationalReadiness is the next
largest ordinary eligible facade.

Blocked:
No.
