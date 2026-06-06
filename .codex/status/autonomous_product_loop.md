# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Candidate-refresh timeline-publication replay branch summary routing.

Status:
Implemented, verified, reviewed, and ready for mechanical commit/push.

Completed slice:
Expose composed timeline-publication replay branch flags on
`CandidateRefresh.source_report_summary/1`.

Why this slice:
The public capability catalog advertises
`source_report_timeline_publication_branch_replay_summary`. The dedicated
`timeline_publication_replay_summary/1` helper already derives branch-local
timeline-publication, dependency, changed-field, invalidation, and review
pressure, but the main `source_report_summary/1` surface only exposes the
underlying timeline-publication rollups.

Level 6 pillar:
Branch-local candidate refresh depth and timeline-publication replay semantics.

What changed:
- `CandidateRefresh.source_report_summary/1` now exposes timeline-publication
  branch-local replay flags for publication, dependency, changed-field,
  invalidation, and review pressure.
- `timeline_publication_replay_summary/1` now uses a private summary builder, so
  the public replay helper and source-report summary fields share the same
  branch-pressure logic without recursing through `source_report_summary/1`.
- Candidate-refresh regression coverage proves the source-report summary
  carries the composed timeline-publication branch flags for raw provenance and
  compact `timeline_publication_summary` provenance.

Verification:
- `mix test test/orbital_dynamics/candidate_refresh_test.exs:25155` passed, 1
  test.
- `mix test test/orbital_dynamics/candidate_refresh_test.exs test/orbital_dynamics/schema_test.exs`
  passed, 823 tests.
- `git diff --check` passed.
- `slice_reviewer` found no must-fix findings.
- No schema export was needed; the emitted `candidate_refresh.v1` artifact
  contract did not change.

Recently completed slices:
- `04f8baf402150ff49d37ad1207a48b895f41f434` pushed to `origin/main` for
  candidate-refresh timeline-integrity replay branch summary routing.
- `cc58d3508d04eb3b857814771667ca1e163bf4b2` pushed to `origin/main` for
  candidate-refresh timeline-diff replay branch summary routing.
- `b845835f24d9c8100a6362fee93872cbf56d3771` pushed to `origin/main` for
  candidate-refresh timeline dependency-impact replay branch summary routing.
- `d7076c3630aeb90c88501b65407ad289958df2fa` pushed to `origin/main` for
  candidate-refresh timeline lifecycle-state replay branch summary routing.
- `b5fdaa91dad915e3281c3bc58526c6b174955836` pushed to `origin/main` for
  candidate-refresh operational-timeline replay branch summary routing.
- `cda28ac62285d0af32591ceb9f6b36201754e942` pushed to `origin/main` for
  candidate-refresh timeline-feedback replay branch summary routing.

Next candidate:
Candidate-refresh timeline-transition-application replay branch summary
routing. The public capability catalog advertises
`source_report_timeline_transition_application_branch_replay_summary`, and
`timeline_transition_application_replay_summary/1` already derives branch-local
transition-application pressure flags that are not yet projected through
`CandidateRefresh.source_report_summary/1`.

Blocked:
No.

Notes:
- `.gitignore` still has an unrelated pre-existing local scratch-ignore change
  and is not part of this slice.
