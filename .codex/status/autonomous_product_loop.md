# Autonomous Product Loop Status

Current slice:
Make CandidateRefresh resource-projection direction routing schema-visible.

Status:
Implemented, locally verified, reviewed clean, committed, and pushed.
Runtime CandidateRefresh resource-projection replay summaries already preserve
direction-scoped resource pressure fields, but the nested
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
  `resource_pressure_direction_counts`, `resource_pressure_directions`,
  `resource_pressure_activity_ids_by_direction`, and
  `resource_pressure_direction_routing`.
- Export tests assert count-map, string-array, stable-ID-array-map, and object
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
- `slice_reviewer`: no must-fix findings.
- `git_slice_publisher`: committed and pushed.

Last completed implementation commit:
`f80a08d54cf5934b94ffecd351e39da98b94c8aa` pushed to `origin/main`.

Last ledger correction commit:
`891ac9c5a0b1fa0e16c24358042e2d0f02a01cd1` pushed to `origin/main`.

Next candidate:
Resource-projection status/type ID routing maps from the mapper result.

Blocked:
No.

Notes:
`.gitignore` still has an unrelated pre-existing local scratch-ignore change and
is not part of this slice. Treat current files as authoritative and do not
revert unrelated changes.
