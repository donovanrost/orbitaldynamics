# Autonomous Product Loop Status

Current slice:
Make CandidateRefresh link-capacity route/source-window maps schema-visible.

Status:
Implemented, locally verified, and reviewed clean; publish pending.
Runtime CandidateRefresh link-capacity source summaries already preserve
direction, source-window, station-calendar, ground-station, spacecraft,
selected/actual-throughput, and requirement-status routing maps, but the
`candidate_refresh.v1` family-specific source-report JSON Schema does not
advertise those link-capacity fields. This is a contract
discoverability slice only: no replay behavior, runtime validation helpers,
artifact generation logic, or operator/Cadence authority behavior changed.

Files changed:
- `.codex/status/autonomous_product_loop.md`
- `lib/orbital_dynamics/schema.ex`
- `schemas/candidate_refresh.v1.schema.json`
- `schemas/orbital_dynamics.schema_bundle.v1.json`
- `test/mix/tasks/orbital_dynamics.schema.export_test.exs`

Definition of done:
- `candidate_refresh.v1` exposes a family-specific `link_capacity_report`
  source-report schema.
- Its source-report object advertises link-capacity row counts, throughput
  totals/maps, selected/actual-throughput ID lists, direction/source-window/
  station-calendar/ground-station/spacecraft/requirement-status ID maps, and
  `direction_routing` route objects with contact, source-window, station
  calendar, and throughput fields.
- Checked-in `candidate_refresh.v1` schema and schema bundle are refreshed.
- Schema export tests, schema tests, schema lint, and whitespace checks pass.

Tests run:
- `mix format lib/orbital_dynamics/schema.ex test/mix/tasks/orbital_dynamics.schema.export_test.exs`
- `mix test test/mix/tasks/orbital_dynamics.schema.export_test.exs`
- `MIX_OS_CONCURRENCY_LOCK=0 mix orbital_dynamics.schema.export --all --directory schemas --output schemas/orbital_dynamics.schema_bundle.v1.json`
- `mix test test/orbital_dynamics/schema_test.exs`
- `mix test test/mix/tasks/orbital_dynamics.schema.export_test.exs`
- `mix orbital_dynamics.schema.lint --all`
- `git diff --check`
- `jq` spot-checks for `link_capacity_report` in
  `schemas/candidate_refresh.v1.schema.json` and the schema bundle.
- `slice_reviewer`: no must-fix findings; reran focused export test,
  whitespace check, and generated-schema `jq` spot-checks.
- `git_slice_publisher`: pending.

Last completed implementation commit:
`2e3db4a48f6db94e32d0c1a12ee5370c7d3ff0a3` pushed to `origin/main`.

Last ledger correction commit:
`90162e029b956beceec2967194404e3674ee797b` pushed to `origin/main`.

Next candidate:
Rerun the mapper against the current checkout.

Blocked:
No.

Notes:
`.gitignore` still has an unrelated pre-existing local scratch-ignore change and
is not part of this slice. Treat current files as authoritative and do not
revert unrelated changes.
