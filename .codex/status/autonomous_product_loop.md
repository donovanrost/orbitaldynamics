# Autonomous Product Loop Status

Current slice:
Broad result-artifact branch-refresh source-report shadow handling.

Status:
Implemented and verified. Branch-generated CandidateRefresh requests now collapse
unindexed `mission_state.source_result_artifact.*` /
`mission_state.result_artifact.*` wrapper shadows when an equivalent branch-local
direct `mission_state.*` report is present. The branch-local collapse covers
CandidateRefresh pressure reports used by the broad result-artifact replay case,
including candidate diff/rejection, resource pressure, link capacity, contact
allocation/contention, station-calendar, timeline-diff, objective, constraint,
score-term, and provider-counteroffer reports. Non-branch live wrapper evidence
and established direct/canonical/wrapped summary alias coverage remain counted
independently.

List-valued result-artifact report and summary fields now preserve indexed source
paths, such as
`mission_state.source_result_artifact.source_constraint_report[1]`, while
list-valued row inputs such as `source_contact_intents` keep their unindexed
input path.

Files changed:
- `.codex/status/autonomous_product_loop.md`
- `lib/orbital_dynamics/campaign_planner.ex`
- `lib/orbital_dynamics/candidate_refresh.ex`

Tests run:
- `mix test test/orbital_dynamics/campaign_planner_test.exs:23434 test/orbital_dynamics/campaign_planner_test.exs:25527 test/orbital_dynamics/campaign_planner_test.exs:50606 test/orbital_dynamics/campaign_planner_test.exs:29710 test/orbital_dynamics/campaign_planner_test.exs:25365 test/orbital_dynamics/campaign_planner_test.exs:24997 test/orbital_dynamics/campaign_planner_test.exs:50986`
- `mix test`
- `git diff --check`

Docs/artifacts changed:
No schema or docs changes. This slice preserves existing artifact contracts and
changes branch-refresh request provenance summarization only.

Full-suite status:
`mix test` reports `2817 passed`. The known `:propagator_exit` log still appears
during `test/orbital_dynamics/scenario_runner_test.exs`; the suite exits green.

Review:
`slice_reviewer` and `git_slice_publisher` were unavailable because valid
spawns hit the agent thread limit. Manual scoped review passed. The diff is
limited to branch-refresh source-report path expansion, branch-local
wrapper-shadow deduplication, and this ledger. `.gitignore` still has an
unrelated pre-existing local scratch-ignore change and is not part of this
slice.

Last commit:
Pending final commit for this slice.

Next candidate:
Re-read the guide, ledger, and live worktree before selecting the next slice from
the autonomous queue.

Blocked:
No.

Notes:
Treat current files as authoritative and do not revert unrelated changes.
