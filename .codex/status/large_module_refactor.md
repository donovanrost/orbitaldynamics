# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
RecommendationRiskContext score-term extraction.

Status:
Completed and pushed in `1a4cf909`.

Selected boundary:
Extract score-term context keys, risk classification, and context projection
into `OrbitalDynamics.RecommendationRiskContext.ScoreTerm`.
Preserve all RecommendationRiskContext and downstream public facades.

Selection evidence:
- Excluding the generated/declarative candidate-refresh JSON-schema module,
  live re-ranking places `recommendation_risk_context.ex` at 1,527 lines, the
  largest ordinary eligible facade.
- RecommendationRiskContext delegates sixteen focused risk families, while the
  score-term key registry, context projection, and classifier remain inline at
  lines 353-391, 491, 1,222-1,301, and 1,495-1,497.
- The selected code has one responsibility: identify score-term risks and
  project stable objective, target, activity, scoring, and provenance context.
- Resource margins, timeline integrity, contact/resource filters, objective
  context, and all other risk families remain outside the boundary.
- Exact context keys and order, feedback-scope classification, atom-key
  normalization, list flattening, nil omission, value ordering, non-list
  behavior, public output, and error behavior must remain unchanged.

Implementation:
- Added `OrbitalDynamics.RecommendationRiskContext.ScoreTerm` as the owner of
  the ordered context-key registry, feedback-scope classification, atom-key
  normalization, and complete score-term context projection.
- Replaced the facade key/context implementation with direct delegation while
  preserving every public entry point and downstream consumer.
- Kept resource margins, timeline integrity, contact/resource filters,
  objective context, and all other risk families outside the boundary.
- `recommendation_risk_context.ex` moved from 1,527 to 1,405 lines; the new
  owner is 156 lines.

Verification:
- The focused comprehensive recommendation-pressure baseline passed its one
  test normally; warnings-as-errors remains inapplicable to that file because
  of its two pre-existing signed-zero pattern warnings.
- Exact old/new public parity passed for four deterministic results: the ordered
  key registry, rich atom-keyed context, scope-only classification/omission,
  and non-list input.
- Post-extraction focused and adjacent recommendation-pressure, Cadence import,
  and operator-review verification passed all three selected tests; both
  adjacent consumers passed with warnings-as-errors.
- Static checks confirm the inline key registry, classifier, and guarded
  projection left the facade; xref reports only RecommendationRiskContext as a
  runtime caller.
- Strict warning-clean forced compile passed for 4,023 files.
- Formatting and `git diff --check` passed.

Behavior/schema changes:
None intended.

Last completed slice:
RecommendationRiskContext score-term extraction, selected in `3d2248a4` and
implemented in `1a4cf909`.
`recommendation_risk_context.ex` moved from 1,527 to 1,405 lines; the dedicated
ScoreTerm owner is 156 lines.

Next candidate:
Re-rank the live checkout and select the next bounded facade-preserving
extraction. OperationalReadiness is now the largest ordinary eligible facade at
1,474 lines.

Blocked:
No.
