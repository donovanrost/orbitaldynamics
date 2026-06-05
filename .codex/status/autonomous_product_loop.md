# Autonomous Product Loop Status

Current slice:
Expose CandidateRefresh resource-projection source-report schema property.

Status:
Implemented, locally verified, and reviewed clean; publish pending. Runtime
CandidateRefresh resource-projection source summaries already preserve
projected-resource and invalid-input counts, resource pressure count maps,
source artifact/model count maps, resource pressure ID maps, direction
lists/counts, and resource pressure direction routing. The
`candidate_refresh.v1` source-report JSON Schema now names
`resource_projection_report` as a family-specific source report instead of
leaving it discoverable only through the generic `source_reports`
`additionalProperties` shape. This is a contract discoverability slice only: no
replay behavior, runtime validation helpers, artifact generation logic, or
operator/Cadence authority behavior changed.

Files changed:
- `.codex/status/autonomous_product_loop.md`
- `lib/orbital_dynamics/schema.ex`
- `schemas/candidate_refresh.v1.schema.json`
- `schemas/orbital_dynamics.schema_bundle.v1.json`
- `test/mix/tasks/orbital_dynamics.schema.export_test.exs`

Definition of done:
- `candidate_refresh.v1` exposes a family-specific `resource_projection_report`
  source-report schema.
- Its source-report object advertises projected-resource and invalid-input
  counts, resource pressure count maps, source artifact/model count maps,
  resource pressure ID maps, direction lists/counts, and direction routing.
- Checked-in `candidate_refresh.v1` schema and schema bundle are refreshed.
- Schema export tests, schema tests, schema lint, and whitespace checks pass.

Tests run:
- `mix format lib/orbital_dynamics/schema.ex test/mix/tasks/orbital_dynamics.schema.export_test.exs`
- `mix test test/mix/tasks/orbital_dynamics.schema.export_test.exs`
- `MIX_OS_CONCURRENCY_LOCK=0 mix orbital_dynamics.schema.export --all --directory schemas --output schemas/orbital_dynamics.schema_bundle.v1.json`
- `mix test test/orbital_dynamics/schema_test.exs`
- `mix test test/mix/tasks/orbital_dynamics.schema.export_test.exs`
- `mix orbital_dynamics.schema.lint --all`
- `jq` spot-checks for `resource_projection_report` source-report fields in
  `schemas/candidate_refresh.v1.schema.json` and the schema bundle.
- `git diff --check`
- `slice_reviewer`: no must-fix findings; reran focused export test, schema
  test, schema lint, whitespace check, and generated-schema `jq` spot-checks.

Last completed implementation commit:
Pending for this slice.

Last ledger correction commit:
Pending for this slice.

Next candidate:
After this slice, run a bounded mapper pass to identify the next
schema-visible CandidateRefresh source-report gap.

Blocked:
No.

Notes:
`.gitignore` still has an unrelated pre-existing local scratch-ignore change and
is not part of this slice. Treat current files as authoritative and do not
revert unrelated changes.
