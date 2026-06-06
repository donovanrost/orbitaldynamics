# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Candidate-refresh link-capacity replay branch summary routing.

Status:
Implemented, verified, reviewed, committed, and ready to push.

Product commit:
- `e765930` for candidate-refresh link-capacity replay branch summary routing.

Completed slice:
Expose composed link-capacity replay branch flags on
`CandidateRefresh.source_report_summary/1`.

Why this slice:
The public capability catalog advertises
`source_report_link_capacity_branch_replay_summary`. The dedicated
`link_capacity_replay_summary/1` helper already derives branch-local
link-capacity, capacity-adjusted throughput, downlink-shortfall, and
actual-throughput pressure, but the main `source_report_summary/1` surface only
exposed the underlying link-capacity rollups. Adapter and operator-review
callers can now inspect the composed link-capacity branch flags from the same
source-report summary surface.

Level 6 pillar:
Branch-local candidate refresh depth and resource/contact allocation replay
semantics.

What changed:
- `CandidateRefresh.source_report_summary/1` now exposes link-capacity
  branch-local replay flags for link-capacity, capacity-adjusted throughput,
  downlink-shortfall, and actual-throughput pressure.
- `link_capacity_replay_summary/1` now uses a private summary builder, so the
  public replay helper and source-report summary fields share the same branch
  pressure logic without recursing through `source_report_summary/1`.
- Candidate-refresh regression coverage proves the source-report summary
  carries the composed link-capacity branch flags for raw provenance and compact
  `link_capacity_summary.v1` input paths.

Verification:
- `mix test test/orbital_dynamics/candidate_refresh_test.exs:9250 test/orbital_dynamics/candidate_refresh_test.exs:10783`
  passed, 2 tests.
- `mix test test/orbital_dynamics/candidate_refresh_test.exs test/orbital_dynamics/schema_test.exs`
  passed, 823 tests.
- `git diff --check` passed.
- `slice_reviewer` found no must-fix findings and independently reran focused
  link-capacity lines plus schema tests.
- No schema export was needed; the emitted `candidate_refresh.v1` artifact
  contract did not change.

Recently completed slices:
- `e765930` committed locally for candidate-refresh link-capacity replay branch
  summary routing.
- `4550570612960efad1389a433a5af60791d33d33` pushed to `origin/main` for the
  autonomous loop handoff after contact-allocation replay summary routing.
- `6f18750` pushed to `origin/main` for candidate-refresh contact-allocation
  replay branch summary routing.
- `e1c7132f4d628f2a39a78bb77ee0e2da4179390a` pushed to `origin/main` for the
  autonomous loop handoff after station-reservation replay summary routing.
- `2df94130bfe05bc722c92dd65be7ece207059ee6` pushed to `origin/main` for
  candidate-refresh station-reservation replay branch summary routing.
- `dd17e14c2597bb0ea21c4ef17c2e9a2797d1750f` pushed to `origin/main` for the
  autonomous loop handoff after contact-intent replay summary routing.
- `8cc9e44620e0dbc3b130f7936fc6e10aa3fdcdea` pushed to `origin/main` for
  candidate-refresh contact-intent replay branch summary routing.

Next candidate:
Candidate-refresh contact-filter replay branch summary routing. The public
capability catalog advertises `source_report_contact_filter_branch_replay_summary`,
and `contact_filter_replay_summary/1` already derives branch-local pressure
flags that are not yet projected through `CandidateRefresh.source_report_summary/1`.

Blocked:
No.

Notes:
- `.gitignore` still has an unrelated pre-existing local scratch-ignore change
  and is not part of this slice.
