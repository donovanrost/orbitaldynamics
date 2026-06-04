# Autonomous Product Loop Status

Current slice:
ResourceProjection nested contact-allocation status roll-forward.

Status:
Implemented and verification passed. ResourceProjection already ignored direct
deferred/policy-blocked contact-allocation rows during selected-flow
storage/downlink roll-forward, but branch-local replay can carry those fields
under nested `source_contact_allocation` evidence. The mapper now reads nested
allocation status/reason/capacity-pack status and nested capacity-pack capacity
fraction evidence from both top-level source allocation context and
`source_station_calendar_entry.source_contact_allocation`, so replayed deferred
or policy-blocked contacts remain zero-effect and allocated contacts keep
capacity-adjusted downlink relief.

Files changed:
- `.codex/status/autonomous_product_loop.md`
- `lib/orbital_dynamics/resource_projection.ex`
- `test/orbital_dynamics/resource_projection_test.exs`

Tests run:
- `mix format lib/orbital_dynamics/resource_projection.ex test/orbital_dynamics/resource_projection_test.exs`
- `mix test test/orbital_dynamics/resource_projection_test.exs:3545`
- `mix test test/orbital_dynamics/resource_projection_test.exs:3160 test/orbital_dynamics/resource_projection_test.exs:3329 test/orbital_dynamics/resource_projection_test.exs:3398 test/orbital_dynamics/resource_projection_test.exs:3545`
- `mix test test/orbital_dynamics/resource_projection_test.exs`

Docs/artifacts changed:
No docs, schema exports, or artifacts changed. The slice uses existing
ResourceProjection flow rows and existing `resource_projection_report.v1` /
`resource_projection_flow_summary.v1` contracts.

Last commit:
Current slice commit is pushed to `origin/main`. `slice_reviewer` and
`git_slice_publisher` were both unavailable because valid spawns hit the agent
thread limit, so publish was performed manually with scoped staging. Local
review checked the scoped diff, focused tests, ledger accuracy, and whitespace;
no publish blockers were found. The unrelated `.gitignore` scratch-ignore
change was left unstaged.

Next candidate:
After this slice is reviewed and pushed, re-read the guide/ledger/live worktree
and continue with the highest-priority unimplemented typed activity,
resource/communications, quality/readiness, or validation slice. Typed timeline,
unavailable-resource quality gates, provider counteroffers, and many
CandidateRefresh resource/communications replay surfaces looked implemented in
the live checkout; treat broad partial/future wording as suspect until checked
against live code.

Blocked:
No.

Notes:
Treat current files as authoritative and do not revert unrelated changes.
`.gitignore` still has an unrelated pre-existing local scratch-ignore change and
is not part of this slice.
