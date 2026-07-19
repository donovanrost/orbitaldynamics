# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
RecommendationRiskContext operational-feedback extraction.

Status:
Selected; implementation not started.

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
Pending.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
Study.Manifest input-field extraction, selected in `6f2faa18` and implemented
in `2cd566e6`. `study/manifest.ex` moved from 4,489 to 4,260 lines; the
dedicated owner is 195 lines.

Next candidate:
Implement and verify the selected RecommendationRiskContext operational-
feedback extraction.

Blocked:
No.
