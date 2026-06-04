# Autonomous Product Loop Status

Current slice:
Contact-intent summary stale direction-routing validation.

Status:
Implemented and verified. `contact_intent_summary.v1` now emits row-derived
`direction_counts` and `direction_routing` alongside the existing compact
direction/contact/capacity aggregates. Schema validation rejects stale direction
counts and route maps that no longer match the row-derived
`contact_ids_by_direction` and capacity-pack direction aggregates. Empty
contact-intent summaries validate without crashing and reject non-empty stale
direction counts when no direction rows are present.

Files changed:
- `.codex/status/autonomous_product_loop.md`
- `docs/artifacts/compatibility_checks.md`
- `lib/orbital_dynamics/communications/contact_intent.ex`
- `lib/orbital_dynamics/schema.ex`
- `schemas/contact_intent_summary.v1.schema.json`
- `schemas/orbital_dynamics.schema_bundle.v1.json`
- `test/orbital_dynamics/communications/contact_intent_test.exs`

Tests run:
- `mix format lib/orbital_dynamics/communications/contact_intent.ex lib/orbital_dynamics/schema.ex test/orbital_dynamics/communications/contact_intent_test.exs`
- `mix test test/orbital_dynamics/communications/contact_intent_test.exs:7 test/orbital_dynamics/communications/contact_intent_test.exs:1020 test/orbital_dynamics/schema_test.exs test/orbital_dynamics/candidate_refresh_test.exs:2565 test/orbital_dynamics/candidate_refresh_test.exs:2625 test/orbital_dynamics/candidate_refresh_test.exs:2778 test/orbital_dynamics/candidate_refresh_test.exs:3000 test/orbital_dynamics/candidate_refresh_test.exs:3077 test/orbital_dynamics/candidate_refresh_test.exs:3160 test/orbital_dynamics/candidate_refresh_test.exs:3239`
- `mix test`
- `git diff --check`

Docs/artifacts changed:
`docs/artifacts/compatibility_checks.md` now documents the row-derived
direction counts/routing and stale-map rejection. Schema exports were refreshed
with:
`MIX_OS_CONCURRENCY_LOCK=0 mix orbital_dynamics.schema.export --all --directory schemas --output schemas/orbital_dynamics.schema_bundle.v1.json`.

Full-suite status:
`mix test` reports `2817 passed`. The known `:propagator_exit` log still appears
during `test/orbital_dynamics/scenario_runner_test.exs`; the suite exits green.

Review:
`slice_reviewer` was unavailable because spawning hit the agent thread limit.
Manual scoped review passed after catching and fixing the empty-summary
validation crash. `git_slice_publisher` was also unavailable because spawning
hit the agent thread limit, so publish was handled locally. `.gitignore` still
has an unrelated pre-existing local scratch-ignore change and is not part of
this slice.

Next candidate:
Re-read the guide, ledger, and live worktree before selecting the next slice from
the autonomous queue.

Blocked:
No.

Notes:
Treat current files as authoritative and do not revert unrelated changes.
