# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Make explicitly blocked timeline activity preconditions affect default V3
recommendation selection.

Status:
Implemented, parent-reviewed, and verified. Publish pending.

Why this slice:
Typed timeline semantics are the highest-priority Level 6 product pillar. The
planner already replayed and scored `timeline_activity_precondition_review`
risks with separate blocked and review counts, but the default approval policy
did not consume the explicit blocked evidence. A high-scoring branch could
therefore remain recommended despite a known blocked activity precondition.

Files changed:
- `lib/orbital_dynamics/campaign_planner/types.ex`
- `lib/orbital_dynamics/policy/blocked_risk_matcher.ex`
- `test/orbital_dynamics/policy_test.exs`
- `test/orbital_dynamics/campaign_planner/strategy_timeline_precondition_recommendation_test.exs`
- `study_results/campaign_repair_readiness_source_handoff_v2.json`
- `.codex/status/autonomous_product_loop.md`

Behavior changed:
The default V3 approval policy now includes the semantic alias
`timeline_activity_precondition_blocked`. It matches only canonical explicit
block evidence: `precondition_status: blocked`, a positive
`blocked_precondition_count`, or
`required_operator_action: review_blocked_activity_precondition`. A blocked
high-value branch remains visible with `policy_decision.v1` provenance but is
skipped for recommendation; review-only and unknown precondition pressure
remain eligible for operator-reviewed selection.

Docs read:
- `docs/feature_set/capability_map/08_mission_activities_and_timelines.md`
- Typed-activity and integrity subpages linked from that capability map.
- `docs/mission_planning/high_fidelity/04_plan_structure_and_lifecycle.md`

Verification:
- Focused matcher and V3 selection regression: `2 passed`.
- Policy, timeline-precondition, and exact V2 fixture set: `96 passed`.
- Campaign-planner plus policy surface: `827 passed`.
- V2 fixture schema validation: pass, zero errors/warnings.
- Full `mix test --timeout 180000`: `3445 passed`.
- Changed Elixir files are formatted; `git diff --check` passes.
- Canonical comparison against `HEAD` proves the regenerated V2 artifact differs
  only by the new alias in its serialized default `blocked_risk_types` list.

Artifact regeneration:
`study_results/campaign_repair_readiness_source_handoff_v2.json` was regenerated
through public `OrbitalDynamics.campaign_repair/1` using the fixture's documented
request builder. No operational side effects or external providers were used.

Level 6 pillar advanced:
Typed activity models and timeline semantics, with operator-visible selection
behavior and deterministic artifact compatibility.

Parent review:
No must-fix findings. The review tightened the focused behavior test to assert
branch-local fallback-policy provenance. Sidecar delegation is unavailable
under the active runtime policy, so the parent performed the mechanical review.

Previous published slice:
- `a7f809b6` Normalize derived campaign golden bytes.
- Full-suite baseline after that publish: `3443 passed`.

Current publish:
- Commit pending.

Remaining maturity gaps:
- Reassess other typed-timeline pressure families, selecting only those with
  unambiguous hard-block semantics rather than review-only evidence.
- Continue contact/resource/readiness selection behavior where explicit block
  evidence is still only scored.
- Continue deeper numerical/backend and resource-model maturity separately.

Blocked:
Not blocked.
