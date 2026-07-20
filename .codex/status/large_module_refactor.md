# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
RecommendationRiskContext maneuver-execution-uncertainty extraction.

Status:
Completed and pushed in `1f5f9672`.

Selected boundary:
Extract maneuver-execution-uncertainty context keys, risk classification, and
context projection into
`OrbitalDynamics.RecommendationRiskContext.ManeuverExecutionUncertainty`.
Preserve all RecommendationRiskContext and downstream public facades.

Selection evidence:
- Excluding the generated/declarative candidate-refresh JSON-schema module,
  live re-ranking places `recommendation_risk_context.ex` at 1,650 lines, the
  largest ordinary eligible facade.
- RecommendationRiskContext already delegates fifteen focused risk families,
  while maneuver-execution-uncertainty keys, projection, and classification
  remain inline at lines 417-443, 526-527, 1,391-1,468, and 1,558-1,576.
- The selected code has one responsibility: identify maneuver execution
  uncertainty risks and project their stable review context.
- Resource margins, timeline integrity, score terms, operational feedback, and
  all other risk families remain outside the boundary.
- Exact context keys and order, accepted type/risk_type/feedback_scope forms,
  atom-key normalization, list flattening, nil omission, value ordering,
  non-list behavior, public output, and error behavior must remain unchanged.

Implementation:
- Added
  `OrbitalDynamics.RecommendationRiskContext.ManeuverExecutionUncertainty` as
  the owner of the context-key registry, accepted risk forms, atom-key
  normalization, and maneuver execution uncertainty context projection.
- Replaced the facade implementation with direct key/context delegation while
  preserving every public entry point and downstream consumer.
- Kept resource margins, timeline integrity, score terms, operational feedback,
  and all other risk families outside the boundary.
- `recommendation_risk_context.ex` moved from 1,650 to 1,527 lines; the new
  owner is 144 lines.

Verification:
- The focused comprehensive recommendation-pressure baseline passed its one
  test normally; warnings-as-errors remains inapplicable to that file because
  of its two pre-existing signed-zero pattern warnings.
- Exact old/new public parity passed for four deterministic results: the ordered
  key registry, rich atom-keyed context, all three accepted classifier forms,
  and non-list input.
- Post-extraction focused and adjacent recommendation-pressure, Cadence import,
  and operator-review verification passed all three selected tests; both
  adjacent consumers passed with warnings-as-errors.
- Static checks confirm the inline key registry, classifier, and guarded
  projection left the facade; xref reports only RecommendationRiskContext as a
  runtime caller.
- Strict warning-clean forced compile passed for 4,017 files.
- Formatting and `git diff --check` passed.

Behavior/schema changes:
None intended.

Last completed slice:
RecommendationRiskContext maneuver-execution-uncertainty extraction, selected
in `e8a5043c` and implemented in `1f5f9672`.
`recommendation_risk_context.ex` moved from 1,650 to 1,527 lines; the dedicated
ManeuverExecutionUncertainty owner is 144 lines.

Next candidate:
Re-rank the live checkout and select the next bounded facade-preserving
extraction. OperationalReadiness is now the largest ordinary eligible facade at
1,635 lines, followed by ContactContention and ResourceFilter.

Blocked:
No.
