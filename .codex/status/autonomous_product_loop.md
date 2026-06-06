# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Candidate-refresh storage/downlink replay summary routing.

Status:
Implemented, verified, and committed locally.

Product commit:
- `e3a20370f9f905b4d0dc607f9f7c0f2f2d69347d` for candidate-refresh
  storage/downlink replay summary routing.

Completed slice:
Expose composed storage/downlink pressure replay routing on
`CandidateRefresh.source_report_summary/1`.

Why this slice:
The public capability catalog advertises source-report storage/downlink branch
replay and provider-routing maps. The dedicated
`storage_downlink_pressure_replay_summary/1` helper already composes
contact-allocation, link-capacity, and resource-projection evidence, but
`source_report_summary/1` only exposes the component family maps. Adapter and
operator-review callers should be able to inspect the composed replay flags and
provider routing from the same source-report summary surface without invoking a
second helper.

Level 6 pillar:
Branch-local candidate refresh depth and resource/contact allocation replay
semantics.

What changed:
- `CandidateRefresh.source_report_summary/1` now exposes composed
  `source_report_storage_downlink_pressure_*` branch-local replay flags.
- The same summary surface now includes capacity-adjusted throughput station
  and direction maps plus provider/provider-entry routing maps from the
  storage/downlink replay helper.
- `storage_downlink_pressure_replay_summary/1` now reuses a private
  source-report-normalized helper so the composed source-summary fields and the
  public helper cannot drift.
- Candidate-refresh regression coverage proves the source-report summary
  carries the composed replay and provider-routing evidence.

Verification:
- `mix test test/orbital_dynamics/candidate_refresh_test.exs:12880` passed, 1
  test.
- `mix test test/orbital_dynamics/candidate_refresh_test.exs` passed, 702
  tests.
- `mix test test/orbital_dynamics/candidate_refresh_test.exs test/orbital_dynamics/schema_test.exs`
  passed, 823 tests.
- `git diff --check` passed.
- No schema export was needed; the emitted `candidate_refresh.v1` artifact
  contract did not change.

Recently completed slices:
- `e3a20370f9f905b4d0dc607f9f7c0f2f2d69347d` committed locally for
  candidate-refresh storage/downlink replay summary routing.
- `a8ab88c0e2c2d9a70b81aa4002623c6f518412af` pushed to `origin/main` for V1
  campaign timeline-integrity report attachment.
- `c7e5b71a3af67158a25e923d9bbf53d0e96bb7bc` pushed to `origin/main` for V1
  campaign activity-precondition summary attachment.
- `402a3692444dbbb697391da8bf9d4bee214b9790` pushed to `origin/main` for V1
  campaign resource-projection flow summary attachment.
- `375037e65ec3b1de1688cfc1f1273f5e49e4037b` pushed to `origin/main` for V1
  campaign readiness and quality-gate attachment.
- `625a2aac24b2ba5d0117efe649968357ea763cd9` pushed to `origin/main` for
  subsystem-state required-state precondition rows.
- `61315e1a0e0a2b2ca43c70d420f852ea2bf60c36` pushed to `origin/main` for
  artifact-only subsystem-state hints on `activity_template.v1`.
- `676e536c74ffdb1a03ac276f16ef8874df121635` pushed to `origin/main` for
  validation-reference fixture coverage for `resource_projection_flow_summary.v1`.

Next candidate:
Select the next Level 6 slice from the live checkout after committing and
pushing the current slice.

Blocked:
No.

Notes:
- `.gitignore` still has an unrelated pre-existing local scratch-ignore change
  and is not part of this slice.
