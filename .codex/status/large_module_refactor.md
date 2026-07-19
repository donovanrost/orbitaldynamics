# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
RecommendationRiskContext objective-satisfaction projection extraction.

Status:
Completed and pushed in `2814c640`.

Selected boundary:
Extract objective-satisfaction context keys, risk selection, and context-value
projection into
`OrbitalDynamics.RecommendationRiskContext.ObjectiveSatisfaction`.
Preserve the existing RecommendationRiskContext public API facade.

Selection evidence:
- Live re-ranking places `recommendation_risk_context.ex` at 3,754 lines,
  fourth behind Schema, Timeline, and MissionPlan.Activity and ahead of
  StationCalendar, LinkCapacity, ResourceProjection, TimelineFeedback, and
  Manifest.
- The selected family owns one risk-domain projection responsibility: its
  exported context-key contract, objective-satisfaction risk selection, and
  deterministic aggregation of values from matching risks.
- Score-term, objective-tradeoff, resource-margin, operational-feedback, and
  all other risk projections remain outside this boundary.
- Existing public APIs, atom/string key normalization, list flattening,
  nil/duplicate removal, empty-key omission, and deterministic output remain
  unchanged.

Verification:
- Strict test-environment compile passed with warnings as errors across 3,914
  files.
- Focused objective-satisfaction operator-review and recommendation-pressure
  coverage passed: 3 tests.
- Adjacent Cadence import, operator-review artifact, and schema contract
  coverage passed: 75 tests.
- Exact public old/new comparison against selection commit `6244115e` passed
  for the context-key contract and seven context samples covering the full
  projected field set, atom/string keys, list flattening, duplicates, nils,
  unrelated risks, and invalid inputs.
- `mix xref callers` reports only the RecommendationRiskContext facade as a
  runtime caller of the extracted objective-satisfaction owner.
- Static ownership checks confirm the context-key contract, risk selector, and
  value projection live in the dedicated owner while adjacent risk domains
  remain in the facade.
- `git diff --check` passed.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
RecommendationRiskContext objective-satisfaction projection extraction,
selected in `6244115e` and implemented in `2814c640`.
`recommendation_risk_context.ex` moved from 3,754 to 3,582 lines; the dedicated
objective-satisfaction owner is 110 lines.

Next candidate:
Re-rank the live largest-module set and select the next cohesive ownership
boundary.

Blocked:
No.
