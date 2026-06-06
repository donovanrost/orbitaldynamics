# Autonomous Product Loop Status

Current slice:
Expose resource-projection row battery quantity and state schemas.

Status:
Implemented, locally verified, and read-only reviewed clean; pending publish.

Discovery:
After the resource-projection storage/downlink pressure quantity slice, live
fixture/schema comparison for `resource_projection_report.v1`
`projected_resources` still shows battery roll-forward fields emitted by the
projection fixture without named projected-resource row schema fields:
`battery_capacity_wh`, `battery_energy_used_wh`, `battery_state_of_charge`,
`starting_battery_energy_used_wh`, `projected_battery_energy_used_wh`,
`projected_battery_state_of_charge`, `projected_power_margin`, and
`projected_battery_overuse_wh`.

Why this matters:
These fields describe the battery baseline and projected post-activity state
behind resource-pressure review. They are the remaining shared projected-resource
row scalar evidence after storage/downlink quantities, and they should reuse the
existing resource-summary contract shape: non-negative watt-hour quantities and
probability-style state/margin fields.

Likely files:
- `.codex/status/autonomous_product_loop.md`
- `lib/orbital_dynamics/schema.ex`
- generated schemas embedding `resource_projection_row_json_schema/0`
- `schemas/orbital_dynamics.schema_bundle.v1.json`
- `test/orbital_dynamics/schema_test.exs`

Definition of done:
- [x] `resource_projection_report.v1` projected-resource row schema exposes the
  eight battery quantity/state fields with non-negative quantity and
  probability-style state/margin shapes.
- [x] Executable validation rejects malformed or out-of-range values for the
  newly exposed battery fields.
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
- `jq -e` spot-checks for projected-resource battery quantity/state fields in
  `schemas/resource_projection_report.v1.schema.json`,
  `schemas/campaign_plan.v1.schema.json`,
  `schemas/resource_projection_flow_summary.v1.schema.json`, and
  `schemas/orbital_dynamics.schema_bundle.v1.json`
- `git diff --check -- . ':!.gitignore'`
- `mix test test/mix/tasks/orbital_dynamics.schema.export_test.exs`
- `mix test test/orbital_dynamics/schema_test.exs`
- `mix orbital_dynamics.schema.lint --all`
- Read-only reviewer reran changed-file/whitespace checks, direct/embedded/bundle
  `jq -e` shape checks, and canonical generated-schema blast-radius comparisons,
  and reported no must-fix findings.

Last completed implementation commit:
`00013f22a373ef2a598fa893a7008e89da27a950` pushed to `origin/main`.

Last ledger correction commit:
`0e0ff0f5e868198fa871bb4414fc881302d3fa13` pushed to `origin/main`.

Next candidate:
Expose remaining battery-handoff-only policy evidence arrays:
`approval_requirements` and `approval_rule_matches`.

Blocked:
No.

Notes:
`.gitignore` still has an unrelated pre-existing local scratch-ignore change and
is not part of this slice. Treat current files as authoritative and do not
revert unrelated changes.
