# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Candidate-refresh resource-projection replay branch summary routing.

Status:
Implemented, verified, reviewed, and ready for mechanical commit/push.

Completed slice:
Expose composed resource-projection replay branch flags on
`CandidateRefresh.source_report_summary/1`.

Why this slice:
The public capability catalog advertises
`source_report_resource_projection_branch_replay_summary`. The dedicated
`resource_projection_replay_summary/1` helper already derives branch-local
resource-projection, projected-resource, invalid-resource-projection, and
activity pressure, but the main `source_report_summary/1` surface only exposed
the underlying resource-projection rollups. Adapter and operator-review callers
can now inspect the composed resource-projection branch flags from the same
source-report summary surface.

Level 6 pillar:
Branch-local candidate refresh depth and resource/contact allocation replay
semantics.

What changed:
- `CandidateRefresh.source_report_summary/1` now exposes resource-projection
  branch-local replay flags for resource-projection, projected-resource,
  invalid-resource-projection, and activity pressure.
- `resource_projection_replay_summary/1` now uses a private summary builder, so
  the public replay helper and source-report summary fields share the same
  branch-pressure logic without recursing through `source_report_summary/1`.
- Candidate-refresh regression coverage proves the source-report summary
  carries the composed resource-projection branch flags for raw provenance and
  compact `resource_projection_report` provenance.

Verification:
- `mix test test/orbital_dynamics/candidate_refresh_test.exs:11348 test/orbital_dynamics/candidate_refresh_test.exs:12001`
  passed, 2 tests.
- `mix test test/orbital_dynamics/candidate_refresh_test.exs test/orbital_dynamics/schema_test.exs`
  passed, 823 tests.
- `git diff --check` passed.
- `slice_reviewer` found no must-fix findings and independently reran focused
  resource-projection plus schema tests.
- No schema export was needed; the emitted `candidate_refresh.v1` artifact
  contract did not change.

Recently completed slices:
- `c388c3d94ee457a391d63bb21e5cb47264f67fdf` pushed to `origin/main` for the
  autonomous loop handoff after resource-filter replay summary routing.
- `bc9bb57` pushed to `origin/main` for candidate-refresh resource-filter
  replay branch summary routing.
- `8b6381b624a9057ca6f3f9547dec9503cbb5143e` pushed to `origin/main` for the
  autonomous loop handoff after contact-filter replay summary routing.
- `bb55b60` pushed to `origin/main` for candidate-refresh contact-filter replay
  branch summary routing.
- `8bb2fb9103b83a8e898c6d6c34f0d964f5433661` pushed to `origin/main` for the
  autonomous loop handoff after link-capacity replay summary routing.
- `e765930` pushed to `origin/main` for candidate-refresh link-capacity replay
  branch summary routing.

Last commit:
Pending mechanical commit/push handoff for this slice.

Next candidate:
Candidate-refresh command-window replay branch summary routing. The public
capability catalog advertises `source_report_command_window_branch_replay_summary`,
and `command_window_replay_summary/1` already derives branch-local command-window
pressure flags that are not yet projected through
`CandidateRefresh.source_report_summary/1`.

Blocked:
No.

Notes:
- `.gitignore` still has an unrelated pre-existing local scratch-ignore change
  and is not part of this slice.
