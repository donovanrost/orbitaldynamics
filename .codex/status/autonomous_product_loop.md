# Autonomous Product Loop Status

Current slice:
ResourceProjection invalid overlap allocation capacity review gate.

Status:
Implemented and verification passed. The live validation path already
review-gated malformed capacity evidence inside
`source_station_calendar_overlaps[*].source_contact_allocation`; this slice locks
that contract down so stale replayed allocation capacity evidence cannot be
silently ignored or projected at full capacity. Invalid nested
`capacity_pack_capacity_fraction` is preserved in `invalid_activity_inputs`
with source evidence and excluded from selected-flow math.

Files changed:
- `.codex/status/autonomous_product_loop.md`
- `test/orbital_dynamics/resource_projection_test.exs`

Tests run:
- `mix format test/orbital_dynamics/resource_projection_test.exs`
- `mix test test/orbital_dynamics/resource_projection_test.exs:3258`
- `mix test test/orbital_dynamics/resource_projection_test.exs:3163 test/orbital_dynamics/resource_projection_test.exs:3258 test/orbital_dynamics/resource_projection_test.exs:3329 test/orbital_dynamics/resource_projection_test.exs:3692`
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
