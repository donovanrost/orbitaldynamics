# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Opt-in V1 ranked-timeline scoring for downlink-completion progress.

Status:
Implemented, parent-reviewed, locally verified, and published locally.
Behavior commit: `be7ffdd`.

Files changed:
- V1 campaign planner:
  `lib/orbital_dynamics/campaign_planner.ex`
- Focused planner coverage:
  `test/orbital_dynamics/campaign_planner_test.exs`
- V1 generation docs:
  `docs/mission_planning/leo_campaign_planner/01_v1_campaign_plan_generation.md`
- Ledger:
  `.codex/status/autonomous_product_loop.md`

Tests/checks run:
- `mix test test/orbital_dynamics/campaign_planner_test.exs:2048`
- `mix test test/orbital_dynamics/campaign_planner_test.exs` (715 passed)
- `mix test` (3327 passed)
- `mix format lib/orbital_dynamics/campaign_planner.ex test/orbital_dynamics/campaign_planner_test.exs`
- `git diff --check`

Behavior changed:
V1 campaign ranking can now opt into downlink-completion objective progress via
`campaign.scoring_policy.downlink_completion_weight`. When a required downlink
MB value comes from campaign objectives or `scoring_policy.required_downlink_mb`,
ranked timelines add deterministic `downlink_completion_score`,
`downlink_completion_ratio`, `selected_downlink_mb`, and `required_downlink_mb`
score-term evidence. The score is capped at full satisfaction and uses the
existing planned-downlink MB helper, including capacity-adjusted throughput when
present. Default behavior is unchanged when the weight is omitted or zero.

Level 6 pillar advanced:
Fleet-level resource/contact behavior and reproducible V1 score explanations:
declared downlink demand can now influence ranked-timeline ordering before the
post-hoc objective, link-capacity, and constraint reports.

Remaining maturity gaps:
- Use selected resource/contact/readiness pressure in additional planner-visible
  selection or scoring paths where live code still leaves it only review-visible.
- Add challenge fixtures for stale-but-plausible lifecycle, provider-calendar,
  readiness, or resource/contact evidence after verifying the target family is
  not already covered.
- Continue reassessing from live code and Level 6 docs between slices; do not
  rely on stale ledger candidates.

Last behavior commit:
`be7ffdd` Score V1 downlink completion progress.

Next candidate:
Recalibrate from the guide and current code. Good next areas are one missing
challenge fixture for stale-but-plausible operational evidence or another
verified planner-visible scoring/selection gap.

Blocked:
Not blocked.

Notes:
- Selection note: V1 already emitted objective, link-capacity, and constraint
  reports for downlink completion, but ranked-timeline scoring had no
  downlink-demand progress term. This slice added an explicit opt-in score term
  rather than changing default campaign artifacts.
- `slice_reviewer` sidecar was not used; the parent completed a bounded local
  review of the ranking path, throughput helper, diff, and full-suite result.
- Full-suite pass still emits the existing campaign-planner `0.0` pattern-match
  warnings; no test failures remain in this slice.
