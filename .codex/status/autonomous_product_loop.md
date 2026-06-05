# Autonomous Product Loop Status

Current slice:
Make CandidateRefresh resource-projection invalid-input/status summary fields schema-visible.

Status:
Implemented, locally verified, and reviewed clean; commit/push pending.
Runtime CandidateRefresh resource-projection replay summaries already preserve
projected-resource, invalid-input, and pressure-status summary fields, but the nested
`candidate_refresh.v1` source-report JSON Schema does not advertise those
fields. This is a contract discoverability slice only: no replay behavior,
runtime validation helpers, artifact generation logic, or operator/Cadence
authority behavior changed.

Files changed:
- `.codex/status/autonomous_product_loop.md`
- `lib/orbital_dynamics/schema.ex`
- `schemas/candidate_refresh.v1.schema.json`
- `schemas/orbital_dynamics.schema_bundle.v1.json`
- `test/mix/tasks/orbital_dynamics.schema.export_test.exs`

Definition of done:
- Nested `candidate_refresh.v1` source-report JSON Schema explicitly includes
  `projected_resource_count`, `invalid_resource_summary_input_count`,
  `invalid_activity_input_ids`, `invalid_resource_summary_input_ids`, and
  `resource_pressure_status_counts`.
- Export tests assert non-negative integer, stable-ID-array, and count-map
  shapes for those nested fields.
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
- `slice_reviewer`: no must-fix findings; tightened export type assertions after
  non-blocking review note.
- `mix format test/mix/tasks/orbital_dynamics.schema.export_test.exs`
- `mix test test/mix/tasks/orbital_dynamics.schema.export_test.exs`
- `git diff --check`
- `git_slice_publisher`: pending.

Last completed implementation commit:
`35f4ba210c831a20e920ec5ddecbf7e180131054` pushed to `origin/main`.

Last ledger correction commit:
`784c818d3d119a543ebff12b5751a65857161138` pushed to `origin/main`.

Next candidate:
Rerun the mapper against the current checkout.

Blocked:
No.

Notes:
`.gitignore` still has an unrelated pre-existing local scratch-ignore change and
is not part of this slice. Treat current files as authoritative and do not
revert unrelated changes.
