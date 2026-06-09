# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Feed branch-local candidate-rejection replay pressure into V3 branch risk and
score terms.

Status:
Completed and pushed.

Files changed:
- Product: `lib/orbital_dynamics/campaign_planner.ex`
- Product test: `test/orbital_dynamics/campaign_planner_test.exs`
- Ledger: `.codex/status/autonomous_product_loop.md`

Tests run:
- `mix test test/orbital_dynamics/campaign_planner_test.exs:37380`
- `mix test test/orbital_dynamics/campaign_planner_test.exs:30370 test/orbital_dynamics/campaign_planner_test.exs:37380 test/orbital_dynamics/campaign_planner_test.exs:48145 test/orbital_dynamics/campaign_planner_test.exs:25930 test/orbital_dynamics/campaign_planner_test.exs:28590`
- `mix format lib/orbital_dynamics/campaign_planner.ex test/orbital_dynamics/campaign_planner_test.exs --check-formatted`
- `git diff --check`
- `mix compile --warnings-as-errors`

Docs/artifacts changed:
No public docs, schema exports, or checked-in JSON artifacts changed.

Level 6 pillar advanced:
Reproducible V1/V2/V3 branch trees with explainable score terms and deltas.

Last completed slice:
Fed branch-local candidate-rejection replay pressure into V3 branch risk and
score terms.

What changed:
- Branch-generated candidate-source candidate-rejection replay pressure now
  emits a `candidate_rejection_pressure` risk with
  `candidate_source.candidate_rejection_replay_summary` provenance.
- The synthetic branch-local candidate-rejection risk is limited to rejected,
  reviewable, or invalid-input pressure, and direct candidate-rejection risks
  still take precedence.
- Branches affected by replayed candidate-rejection pressure now expose
  `candidate_rejection_pressure_penalty` in score terms and the score-term
  report.
- Added focused assertions to the mission-state candidate-rejection replay
  strategy test, including rejected/reviewable/invalid counts, reason/action
  maps, candidate IDs, station IDs, score-term value, and score-term report
  rows.
- Parent performed bounded local review and mechanical publish because no
  suitable subagent tool is available in this runtime.

Last commit:
- Product: `e9293e0` Feed candidate rejection replay into branch scoring
- Ledger: latest `Update autonomous loop handoff` commit on `main`

Remaining maturity gaps:
- Continue making existing review evidence planner-visible through candidate
  selection, branch scoring, compatibility checks, and challenge fixtures.
- Prefer named branch score terms for replayed artifact pressure that currently
  lands only as generic risk.
- Prefer checked-in compatibility or challenge fixtures where live coverage is
  weaker than the Level 6 maturity map.
- Consider readiness/quality-gate pressure affecting candidate selection beyond
  branch recommendation if a live gap is found.

Next candidate:
Reassess branch-local replay families for another pressure signal that is
replayed but not yet planner-visible, or switch to preserving replayed
candidate-source review rows through branch candidate construction if the live
gap justifies the broader shape change.

Blocked:
Not blocked.

Notes:
- `.gitignore` has an unrelated pre-existing local scratch-ignore change and is
  not part of this slice.
- Sidecar delegation is unavailable in this runtime; parent uses the same
  bounded review and mechanical publish scope.
