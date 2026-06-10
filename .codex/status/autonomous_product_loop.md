# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Opt-in V1 timeline scoring accounts for activity precondition pressure.

Status:
Implemented, parent-reviewed, locally verified, and published locally.
Behavior commit: `67e6e3e`.

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
- `mix test test/orbital_dynamics/campaign_planner_test.exs:2196`
- `mix test test/orbital_dynamics/campaign_planner_test.exs` (717 passed)
- `mix test` (3329 passed)
- `mix format lib/orbital_dynamics/campaign_planner.ex test/orbital_dynamics/campaign_planner_test.exs`
- `git diff --check`

Behavior changed:
When `campaign.scoring_policy.timeline_precondition_weight` is positive, V1
candidate metadata can carry explicit timeline activity precondition evidence
into generated observe/contact candidates, and ranked timeline scoring subtracts
deterministic pressure for selected activities with blocked or review-required
timeline preconditions. The pressure appears as score-term evidence in ranked
timelines, score-term reports, and objective tradeoffs. Default behavior remains
unchanged when the weight is omitted or zero.

Level 6 pillar advanced:
Planner-visible operational readiness pressure: activity preconditions are
already summarized after selection, and this slice makes the same candidate
pressure visible to V1 selection/ranking when operators opt in.

Remaining maturity gaps:
- Use selected resource/contact/readiness pressure in additional planner-visible
  selection or scoring paths where live code still leaves it only review-visible.
- Add challenge fixtures for stale-but-plausible lifecycle, provider-calendar,
  readiness, or resource/contact evidence after verifying the target family is
  not already covered.
- Continue reassessing from live code and Level 6 docs between slices; do not
  rely on stale ledger candidates.

Last behavior commit:
`67e6e3e` Score V1 timeline precondition pressure.

Next candidate:
After this slice, reassess from current code. Good next areas are another
verified planner-visible readiness/resource gap or a missing challenge fixture
that current tests do not already cover.

Blocked:
Not blocked.

Notes:
- Selection note: resource and station availability already filter before V1
  ranking, and V3 branch scoring already penalizes readiness/precondition risk.
  The verified V1 gap is candidate-level timeline precondition pressure:
  selected activities receive artifact-only summaries after selection, but that
  pressure was not a score term. This slice adds opt-in precondition scoring
  with focused ranking regression, report evidence, schema-valid artifacts, full
  planner test, full suite, review, commit, and push.
- `slice_reviewer` sidecar was not used; the parent completed a bounded local
  review of the selector path, emitted score terms, diff, and full-suite result.
- Full-suite pass still emits the existing campaign-planner `0.0` pattern-match
  warnings; no test failures remain in this slice.
