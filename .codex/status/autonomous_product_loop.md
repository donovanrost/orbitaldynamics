# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Opt-in V1 timeline scoring accounts for resource projection pressure.

Status:
Implemented, parent-reviewed, locally verified, and published locally.
Behavior commit: `78fe28f`.

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
- `mix test test/orbital_dynamics/campaign_planner_test.exs:2283`
- `mix test test/orbital_dynamics/campaign_planner_test.exs` (718 passed)
- `mix test` (3330 passed)
- `mix format lib/orbital_dynamics/campaign_planner.ex test/orbital_dynamics/campaign_planner_test.exs`
- `git diff --check`

Behavior changed:
When `campaign.scoring_policy.resource_projection_weight` is positive and
campaign resource summaries are supplied, generated observe/contact candidates
carry declared resource-projection estimate metadata and V1 greedy selection and
ranked timeline scoring subtract deterministic pressure for projected storage
overflow, downlink shortfall, battery depletion, or selected activity resource
availability pressure. The pressure appears as numeric score-term evidence in
ranked timelines, score-term reports, and objective tradeoffs. Default behavior
remains unchanged when the weight is omitted or zero.

Level 6 pillar advanced:
Planner-visible fleet resource behavior: V1 already emits selected-activity
resource projection and flow artifacts after selection; this slice reuses that
existing projection evidence to affect selection/ranking when operators opt in.

Remaining maturity gaps:
- Use selected resource/contact/readiness pressure in additional planner-visible
  selection or scoring paths where live code still leaves it only review-visible.
- Add challenge fixtures for stale-but-plausible lifecycle, provider-calendar,
  readiness, or resource/contact evidence after verifying the target family is
  not already covered.
- Continue reassessing from live code and Level 6 docs between slices; do not
  rely on stale ledger candidates.

Last behavior commit:
`78fe28f` Score V1 resource projection pressure.

Next candidate:
After this slice, reassess from current code. Good next areas are another
verified planner-visible readiness/resource gap or a missing challenge fixture
that current tests do not already cover.

Blocked:
Not blocked.

Notes:
- Selection note: the current roadmap asks for existing artifact surfaces to
  become more planner-visible. Resource summaries already filter unavailable
  candidates, and V3 already scores replayed resource-projection pressure, but
  V1 selected storage/downlink/battery pressure is still generated after
  selection. This slice adds opt-in V1 resource-projection scoring using
  existing `ResourceProjection.report/3` evidence, with focused ranking
  regression, report evidence, schema validation, V1 docs, full planner test,
  full suite, review, commit, and push.
- `slice_reviewer` sidecar was not used; the parent completed a bounded local
  review of metadata propagation, score-term numeric shape, default behavior,
  docs, and verification output.
- Full-suite pass still emits the existing campaign-planner `0.0` pattern-match
  warnings; no test failures remain in this slice.
