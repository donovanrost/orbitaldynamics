# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Score command-window replay pressure from candidate-source reports.

Status:
Completed locally; product commit created and ledger commit pending.

Files changed:
- Product: `lib/orbital_dynamics/campaign_planner.ex`
- Tests: `test/orbital_dynamics/campaign_planner_test.exs`;
  `test/orbital_dynamics/golden_artifact_test.exs`
- Fixture: `study_results/leo_constellation_campaign_strategy_v3.json`
- Ledger: `.codex/status/autonomous_product_loop.md`

Tests run:
- `mix test test/orbital_dynamics/campaign_planner_test.exs:24748`
- `mix test test/orbital_dynamics/golden_artifact_test.exs`
- `mix compile --warnings-as-errors`
- `git diff --check`

Docs/artifacts changed:
Regenerated `study_results/leo_constellation_campaign_strategy_v3.json` through
the public V3 strategy facade after the new score term changed the checked
strategy surface.

Level 6 pillar advanced:
Planner-visible command/contact evidence and branch-local scoring for
command-window source-report replay.

Slice selection note:
Selected slice: Score branch-local command-window replay pressure from
candidate-source `command_window_report.v1` summaries.

Why this slice: The live checkout carries mission-state command-window reports
into branch-generated candidate-refresh source summaries and
`CandidateRefresh.command_window_replay_summary/1` advertises branch-local
command-window pressure, but `candidate_source_risk_indicators/2` does not read
that replay summary. As a result, an urgent branch with only source-report
command-window evidence keeps the provenance but lacks a replay risk and score
penalty.

Level 6 pillar: Command/contact evidence, planner-visible feedback, and
artifact-only operator-review boundaries.

Current evidence gap: `CandidateRefresh.command_window_replay_summary/1`
reports `branch_local_command_window_pressure`, `branch_local_command_feedback_pressure`,
and action pressure, but there is no corresponding replay risk added to branch
`risk_indicators`.

Docs read: `docs/feature_set/capability_map/08_mission_activities/partial-and-future.md`;
`docs/feature_set/capability_map/08_mission_activities/command-window-and-timeline-builder.md`;
`docs/artifacts/field_families/mission_activities.md`.

Likely files: `lib/orbital_dynamics/campaign_planner.ex`;
`test/orbital_dynamics/campaign_planner_test.exs`;
`.codex/status/autonomous_product_loop.md`.

Likely tests: focused command-window candidate-source replay campaign-planner
test; `mix compile --warnings-as-errors`; `git diff --check`.

Definition of done:
- Branch-generated candidate sources read command-window replay summaries into
  risk indicators when branch-local command-window pressure exists.
- The replay risk preserves source report counts, source paths, direction
  routing, required operator actions, trust boundaries, and artifact-only
  assumptions.
- Command-window replay risks affect branch scoring through an explicit score
  term and are visible in branch-comparison rows.
- Focused tests, compile, and whitespace checks pass.

What changed:
Branch-generated candidate sources now read
`CandidateRefresh.command_window_replay_summary/1` into branch risk indicators
when replay reports branch-local command-window pressure. The new aggregate
`command_window_pressure` risk preserves source report counts, paths, direction
routing, required operator actions, trust boundaries, and artifact-only
assumptions. Strategy scoring now includes
`command_window_pressure_penalty`, recommendation context preserves the replay
fields, and branch-comparison rows expose command-window source paths,
directions, action counts, and trust boundaries.

Last completed slice:
Scored command-window replay pressure from candidate-source reports.

Last commit:
- Product: `78c3002` Score command-window replay pressure
- Ledger: this handoff commit on `main`

Remaining maturity gaps:
- Continue making existing review evidence planner-visible through candidate
  selection, branch scoring, compatibility checks, and challenge fixtures.
- Continue closing queue-2/queue-3 handoff completeness gaps for branch evidence
  families not present in checked-in strategy artifacts.

Next candidate:
Continue reassessing queue-1 activity/replay families for source-report
evidence that is preserved but not yet scored or comparison-visible.

Blocked:
Not blocked.

Notes:
- `.gitignore` has an unrelated pre-existing local scratch-ignore change and is
  not part of this slice.
- Focused campaign-planner test compilation still emits an existing warning
  about matching on `0.0` in an unrelated readiness/quality-gate test
  definition; the selected test passes, and `mix compile --warnings-as-errors`
  passes.
- Sidecar delegation is unavailable in this runtime; parent uses the same
  bounded review and mechanical publish scope.
