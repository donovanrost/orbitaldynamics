# Autonomous Product Loop Status

Current slice:
Timeline-activity state replay reads and labels V3 branch
`candidate_source.candidate_refresh_request_source_report_summary` metadata.

Status:
Implementation, focused verification, review, product commit, and push are
complete for this slice. This status handoff records the published state.
`CandidateRefresh.timeline_activity_state_replay_summary/1` now checks a
non-empty V3 branch `timeline_activity_state` source-report family before
falling back to provenance. Branch-sourced summaries preserve counts, paths,
summary model/schema counts, state/status/approval/transition/action/import
maps, activity/timeline/review routing, trust-boundary metadata, and
branch-local pressure booleans while labeling their `source` and replay scope
as candidate-source summary metadata. Empty branch families fall back to
provenance and keep existing provenance-only labels; partial non-empty branch
families remain authoritative. Direct `candidate_source` maps use the same
branch labels.

This slice also corrected the executable and exported
`timeline_activity_state.v1` schema model-limit contract to use the
TimelineFeedback activity-state limits emitted by runtime artifacts. The
checked-in schema export and matching study-results fixture were refreshed.

Files changed for this slice:
- `.codex/status/autonomous_product_loop.md`
- `docs/artifacts/field_families/candidate_refresh_artifact.md`
- `docs/artifacts/field_families/mission_activities.md`
- `lib/orbital_dynamics/candidate_refresh.ex`
- `lib/orbital_dynamics/schema.ex`
- `schemas/orbital_dynamics.schema_bundle.v1.json`
- `schemas/timeline_activity_state.v1.schema.json`
- `study_results/timeline_activity_state_v1.json`
- `test/mix/tasks/orbital_dynamics.schema.export_test.exs`
- `test/orbital_dynamics/campaign_planner_test.exs`
- `test/orbital_dynamics/candidate_refresh_test.exs`
- `test/orbital_dynamics/schema_test.exs`

Tests run:
- `mix test test/orbital_dynamics/candidate_refresh_test.exs:13724 test/orbital_dynamics/candidate_refresh_test.exs:14130 test/orbital_dynamics/candidate_refresh_test.exs:14145 test/orbital_dynamics/candidate_refresh_test.exs:14240 test/orbital_dynamics/candidate_refresh_test.exs:14277 test/orbital_dynamics/candidate_refresh_test.exs:14317 --trace --seed 0`
  passed activity-state review/import aggregation, absent-provenance,
  branch candidate-source replay, direct candidate-source labeling,
  empty-family fallback, and partial-family precedence checks.
- `mix test test/orbital_dynamics/campaign_planner_test.exs:25916 test/orbital_dynamics/campaign_planner_test.exs:26051 test/orbital_dynamics/campaign_planner_test.exs:26189 --trace --seed 0`
  passed the three strategy branch refresh callers that pass direct
  candidate-source maps into timeline activity-state replay.
- `mix test test/orbital_dynamics/timeline_test.exs:536 --trace --seed 0`
  passed the runtime activity-state artifact contract check after the
  model-limit correction.
- `mix test test/orbital_dynamics/campaign_planner_test.exs:25916 test/orbital_dynamics/campaign_planner_test.exs:26051 test/orbital_dynamics/campaign_planner_test.exs:26189 test/orbital_dynamics/timeline_test.exs:536 test/orbital_dynamics/schema_test.exs:7184 test/orbital_dynamics/schema_test.exs:7263 test/mix/tasks/orbital_dynamics.schema.export_test.exs:39 --trace --seed 0`
  passed the final combined CampaignPlanner, runtime activity-state, executable
  schema, and export checks after formatting.
- `MIX_OS_CONCURRENCY_LOCK=0 mix orbital_dynamics.schema.export --all --directory schemas --output schemas/orbital_dynamics.schema_bundle.v1.json`
  refreshed the checked-in schema export.
- `mix orbital_dynamics.schema.lint --all` passed after refreshing
  `study_results/timeline_activity_state_v1.json`.
- `git diff --check` passed.

Docs/artifacts changed:
- `docs/artifacts/field_families/candidate_refresh_artifact.md` now documents
  the V3 activity-state branch candidate-source summary preference, source and
  replay-scope labels, partial-family precedence, and provenance fallback.
  `docs/artifacts/field_families/mission_activities.md` carries the matching
  field-family note.
- `schemas/timeline_activity_state.v1.schema.json`,
  `schemas/orbital_dynamics.schema_bundle.v1.json`, and
  `study_results/timeline_activity_state_v1.json` now carry TimelineFeedback
  activity-state model limits.

Last product commit:
- `f17a555a` (`Label activity state branch replay metadata`) pushed to
  `origin/main`.

Next candidate:
After publish, re-read `docs/autonomous_work_guide.md`, this ledger, and the
live worktree before choosing another gap. CandidateRefresh replay helpers
still include provenance-only labels; audit one narrow helper at a time
against docs and existing V3 branch candidate-source call sites.

Blocked:
No.

Notes:
This slice intentionally does not apply activity-state changes, mutate
timelines, select candidates, approve imports, execute commands, write to
Cadence, or regenerate candidates. Treat current files as authoritative and do
not revert unrelated changes. `.gitignore` has an unrelated pre-existing local
scratch-ignore change and is not part of this slice.
