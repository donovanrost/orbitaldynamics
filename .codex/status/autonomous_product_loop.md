# Autonomous Product Loop Status

Current slice:
Expose resource-projection row storage/downlink pressure quantity schemas.

Status:
Implemented, locally verified, and read-only reviewed clean; pending publish.

Discovery:
After the resource-projection ignored-activity slice, live fixture/schema
comparison for `resource_projection_report.v1` `projected_resources` still shows
storage/downlink pressure quantities emitted by both projection fixtures without
named projected-resource row schema fields: `projected_storage_overflow_mb`,
`projected_downlink_shortfall_mb`, `storage_limited_downlinked_mb`, and
`unused_downlink_capacity_mb`.

Why this matters:
These fields carry the concrete storage overflow, downlink shortfall,
downlink-limited storage transfer, and unused capacity quantities behind a
resource-pressure review. They are adapter-facing scalar evidence, distinct from
the already exposed margins and capacities, and should be schema-visible before
tackling the larger battery state group or battery-handoff-only policy evidence.

Likely files:
- `.codex/status/autonomous_product_loop.md`
- `lib/orbital_dynamics/schema.ex`
- generated schemas embedding `resource_projection_row_json_schema/0`
- `schemas/orbital_dynamics.schema_bundle.v1.json`
- `test/orbital_dynamics/schema_test.exs`

Definition of done:
- [x] `resource_projection_report.v1` projected-resource row schema exposes
  `projected_storage_overflow_mb`, `projected_downlink_shortfall_mb`,
  `storage_limited_downlinked_mb`, and `unused_downlink_capacity_mb` as
  non-negative numbers.
- [x] Executable validation rejects malformed values for the newly exposed
  pressure quantity fields.
- [x] Focused schema tests assert row schema shape and representative invalid
  values.
- [x] Checked-in schemas and bundle are refreshed.
- [x] Focused schema tests, schema export tests, schema lint, generated-schema
  spot-checks, and whitespace checks pass.
- [x] Read-only review finds no must-fix issues.
- [ ] Slice-owned files only are committed and pushed.

Tests run:
- `mix format lib/orbital_dynamics/schema.ex test/orbital_dynamics/schema_test.exs`
- `mix test test/orbital_dynamics/schema_test.exs:19622`
- `MIX_OS_CONCURRENCY_LOCK=0 mix orbital_dynamics.schema.export --all --directory schemas --output schemas/orbital_dynamics.schema_bundle.v1.json`
- `jq -e` spot-checks for projected-resource storage/downlink pressure quantity
  fields in `schemas/resource_projection_report.v1.schema.json`,
  `schemas/campaign_plan.v1.schema.json`,
  `schemas/resource_projection_flow_summary.v1.schema.json`, and
  `schemas/orbital_dynamics.schema_bundle.v1.json`
- `git diff --check -- . ':!.gitignore'`
- `mix test test/mix/tasks/orbital_dynamics.schema.export_test.exs`
- `mix test test/orbital_dynamics/schema_test.exs`
- `mix orbital_dynamics.schema.lint --all`
- Read-only reviewer reran changed-file/whitespace checks and structured
  generated-schema comparisons, confirmed the shared non-negative-number
  validation path, and reported no must-fix findings.

Last completed implementation commit:
`731a22e4ec678d5d111b21cf09c0acca4297e16d` pushed to `origin/main`.

Last ledger correction commit:
`975a887e396d82dda2165f025c907c9a66c6e836` pushed to `origin/main`.

Next candidate:
Continue splitting `resource_projection_report.v1` `projected_resources` gaps:
battery quantities/state-of-charge and policy approval evidence.

Blocked:
No.

Notes:
`.gitignore` still has an unrelated pre-existing local scratch-ignore change and
is not part of this slice. Treat current files as authoritative and do not
revert unrelated changes.
