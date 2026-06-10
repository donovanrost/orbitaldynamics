# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Opt-in V1 greedy activity selection uses downlink-completion progress.

Status:
Implemented, parent-reviewed, locally verified, and published locally.
Behavior commit: `63b4c9a`.

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
- `mix test test/orbital_dynamics/campaign_planner_test.exs:2115`
- `mix test test/orbital_dynamics/campaign_planner_test.exs` (716 passed)
- `mix test` (3328 passed)
- `mix format lib/orbital_dynamics/campaign_planner.ex test/orbital_dynamics/campaign_planner_test.exs`
- `git diff --check`

Behavior changed:
When `campaign.scoring_policy.downlink_completion_weight` is positive and a
required downlink MB value is declared, V1 greedy timeline selection now boosts
downlink candidates by their capped downlink-completion progress before applying
overlap and max-activity constraints. Emitted candidate scores stay unchanged;
the selected ranked timeline still carries the deterministic
`downlink_completion_score`, ratio, selected MB, and required MB score-term
evidence. Default behavior remains unchanged when the weight is omitted or zero.

Level 6 pillar advanced:
Fleet-level resource/contact selection behavior and reproducible V1 score
explanations: declared downlink demand can now influence both selection and
ranking before post-hoc review reports.

Remaining maturity gaps:
- Use selected resource/contact/readiness pressure in additional planner-visible
  selection or scoring paths where live code still leaves it only review-visible.
- Add challenge fixtures for stale-but-plausible lifecycle, provider-calendar,
  readiness, or resource/contact evidence after verifying the target family is
  not already covered.
- Continue reassessing from live code and Level 6 docs between slices; do not
  rely on stale ledger candidates.

Last behavior commit:
`63b4c9a` Use downlink progress in V1 selection.

Next candidate:
Recalibrate from the guide and current code. Good next areas are one verified
planner-visible readiness/resource gap or a missing challenge fixture that
current tests do not already cover.

Blocked:
Not blocked.

Notes:
- Selection note: after the previous slice, downlink demand affected ranked
  timeline scores but not the greedy selection order. This slice applies the
  same opt-in progress signal during candidate ordering while keeping default
  artifacts stable.
- `slice_reviewer` sidecar was not used; the parent completed a bounded local
  review of the selector path, emitted score terms, diff, and full-suite result.
- Full-suite pass still emits the existing campaign-planner `0.0` pattern-match
  warnings; no test failures remain in this slice.
