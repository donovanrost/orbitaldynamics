# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
RecommendationRiskContext operational-feedback extraction.

Status:
Completed and pushed in `8ee8763d`.

Selected boundary:
Extract the operational-feedback context-key registry, risk classification,
key normalization, value collection, and public context assembly into
`OrbitalDynamics.RecommendationRiskContext.OperationalFeedback`. Preserve
`operational_feedback_context_keys/0` and `operational_feedback_context/1` as
public facade delegates.

Selection evidence:
- Live re-ranking places `recommendation_risk_context.ex` at 4,033 lines,
  behind the larger Schema, Timeline, TimelineFeedback, MissionPlan.Activity,
  and Study.Manifest facades.
- The selected 973-1,052 registry and 3,651-3,834 assembly form one cohesive
  operational-feedback responsibility with no dependency on other context
  families.
- The existing public facade is consumed by strategy recommendation import,
  manifest-row, and operator-review paths; those call sites remain unchanged.
- Execution-success feedback, shared context families, and all other risk
  registries and assemblers remain in the facade.

Verification:
- Strict warnings-as-errors compile passed across 3,890 files.
- Focused strategy-recommendation pressure-event coverage passed: 1 test. The
  test file emits two pre-existing `0.0` pattern warnings, so its
  warnings-as-errors baseline and post-extraction runs abort after the passing
  assertion; the post-extraction proof was therefore also run without
  warnings-as-errors and passed.
- Adjacent operational-feedback provenance, source-feedback provenance,
  Cadence comparison-report, and operator-review strategy-artifact coverage
  passed under warnings-as-errors: 19 tests.
- Exact public old/new comparison against `dc4a34a0` passed the ordered 77-key
  registry and 9 input cases covering scalar/list values, atom-key
  normalization, all three matching risk types, mixed risks, ignored risks,
  and invalid inputs.
- `mix xref callers
  OrbitalDynamics.RecommendationRiskContext.OperationalFeedback` reports only
  the RecommendationRiskContext facade as a runtime caller.
- Static ownership review confirms the registry, classifier, normalizer,
  collector, and assembler live in the new owner; the facade retains only the
  two public delegates.
- `git diff --check` passed.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
RecommendationRiskContext operational-feedback extraction, selected in
`dc4a34a0` and implemented in `8ee8763d`.
`recommendation_risk_context.ex` moved from 4,033 to 3,754 lines; the dedicated
owner is 158 lines.

Next candidate:
Re-rank the remaining large modules and select the next cohesive,
facade-preserving responsibility boundary.

Blocked:
No.
