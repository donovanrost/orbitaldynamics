# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
RecommendationRiskContext resource-margin extraction.

Status:
Completed and pushed in `015526be`.

Selected boundary:
Extract resource-margin context keys, risk classification, and context
projection into `OrbitalDynamics.RecommendationRiskContext.ResourceMargin`.
Preserve all RecommendationRiskContext and downstream public facades.

Selection evidence:
- Excluding the generated/declarative candidate-refresh JSON-schema module,
  live re-ranking places `recommendation_risk_context.ex` at 1,405 lines, the
  largest ordinary eligible facade.
- RecommendationRiskContext delegates seventeen focused risk families, while
  the resource-margin key registry, projection, and classifier remain inline at
  lines 354-377, 458, 1,189-1,244, and 1,315-1,335.
- The selected code has one responsibility: identify resource-margin risks and
  project stable spacecraft, margin, threshold, activity, review, and
  provenance context.
- Timeline integrity, contact/resource filters, objective/score-term context,
  and all other risk families remain outside the boundary.
- Exact context keys and order, resource-field/type classification, atom-key
  normalization, list flattening, nil omission, value ordering, non-list
  behavior, public output, and error behavior must remain unchanged.

Implementation:
- Added `OrbitalDynamics.RecommendationRiskContext.ResourceMargin` as the owner
  of the ordered context-key registry, resource-field/type classification,
  atom-key normalization, and complete resource-margin context projection.
- Replaced the facade key/context implementation with direct delegation while
  preserving every public entry point and downstream consumer.
- Kept timeline integrity, contact/resource filters, objective/score-term
  context, and all other risk families outside the boundary.
- `recommendation_risk_context.ex` moved from 1,405 to 1,304 lines; the new
  owner is 136 lines.

Verification:
- The focused comprehensive recommendation-pressure baseline passed its one
  test normally; warnings-as-errors remains inapplicable to that file because
  of its two pre-existing signed-zero pattern warnings.
- Exact old/new public parity passed for four deterministic results: the ordered
  key registry, rich atom-keyed context, both accepted classifier forms with
  omission, and non-list input.
- Post-extraction focused and adjacent recommendation-pressure, Cadence import,
  and operator-review verification passed all three selected tests; both
  adjacent consumers passed with warnings-as-errors.
- Static checks confirm the inline key registry, classifiers, and guarded
  projection left the facade; xref reports only RecommendationRiskContext as a
  runtime caller.
- Strict warning-clean forced compile passed for 4,025 files.
- Formatting and `git diff --check` passed.

Behavior/schema changes:
None intended.

Last completed slice:
RecommendationRiskContext resource-margin extraction, selected in `abd70a00`
and implemented in `015526be`.
`recommendation_risk_context.ex` moved from 1,405 to 1,304 lines; the dedicated
ResourceMargin owner is 136 lines.

Next candidate:
Re-rank the live checkout and select the next bounded facade-preserving
extraction. OperationalReadiness is now the largest ordinary eligible facade at
1,388 lines.

Blocked:
No.
