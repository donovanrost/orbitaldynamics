# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
RecommendationRiskContext validation-refresh extraction.

Status:
Completed and pushed in `cfae3494`.

Selected boundary:
Extract the validation-refresh context-key contract and deterministic
aggregation for model-acceptance, schema-validation, validation-safety-case,
refresh-budget, and refresh-freshness risks into
`OrbitalDynamics.RecommendationRiskContext.ValidationRefresh`.
Preserve the existing RecommendationRiskContext public API facade.

Selection evidence:
- Live re-ranking places `recommendation_risk_context.ex` at 3,582 lines,
  fourth behind Schema, Timeline, and MissionPlan.Activity and ahead of
  OrbitalDynamics, Manifest, LinkCapacity, StationCalendar, TimelineFeedback,
  ResourceProjection, and ContactAllocation.
- The selected family owns one recommendation explanation responsibility:
  translating validation and refresh risk rows into the declared compact
  context vocabulary used by downstream recommendations.
- Approval, communications, timeline, resource, objective, and operational
  feedback context families remain outside this boundary.
- Existing risk matching, atom/string normalization, list flattening,
  encounter-order deduplication, empty-value omission, invalid-input behavior,
  and public context-key ordering remain unchanged.

Verification:
- Strict test-environment compile passed with warnings as errors across 3,925
  files.
- Focused validation/refresh campaign-planner coverage passed: 19 tests.
- Broader recommendation/readiness coverage passed 19 of 20 tests. The one
  readiness score-count assertion failure was reproduced unchanged at clean
  selection commit `bbc28b0e` in a detached worktree, so it is a pre-existing
  baseline failure rather than a slice regression.
- Exact public old/new comparison against selection commit `bbc28b0e` passed
  for the complete public context-key contract, six mixed risk sets covering
  all five validation/refresh families, and four invalid inputs.
- `mix xref callers` reports only the RecommendationRiskContext facade as a
  runtime caller of the extracted validation-refresh owner.
- Static ownership checks confirm the key vocabulary, family matching,
  normalization, aggregation, deduplication, and omission behavior live in the
  dedicated owner while all other recommendation-risk families remain in the
  facade.
- `git diff --check` passed.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
RecommendationRiskContext validation-refresh extraction, selected in
`bbc28b0e` and implemented in `cfae3494`.
`recommendation_risk_context.ex` moved from 3,582 to 3,293 lines; the dedicated
validation-refresh owner is 170 lines.

Next candidate:
Re-rank the live largest-module set and select the next cohesive ownership
boundary.

Blocked:
No.
