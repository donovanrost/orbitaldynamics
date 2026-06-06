# Autonomous Product Loop Status

Current slice:
Expose resource-projection row effective and ignored activity schemas.

Status:
Implemented, locally verified, read-only reviewed clean, committed, and pushed.

Discovery:
After the resource-projection row metadata slice, live fixture/schema comparison
still shows both `resource_projection_report.v1` projection fixtures emitting
row-level `effective_activity_count`, `ignored_activity_count`, and
`ignored_activity_ids` from `projected_resources` without those fields named in
the projected-resource row schema.

Why this matters:
These row fields explain which selected activities actually affected the thin
resource roll-forward and which were preserved as ignored/no-effect evidence.
They are already count-consistency checked by executable validation, but
downstream review/import adapters need the exported row schema to expose their
integer and stable-ID shapes.

Likely files:
- `.codex/status/autonomous_product_loop.md`
- `lib/orbital_dynamics/schema.ex`
- generated schemas embedding `resource_projection_row_json_schema/0`
- `schemas/orbital_dynamics.schema_bundle.v1.json`
- `test/orbital_dynamics/schema_test.exs`

Definition of done:
- [x] `resource_projection_report.v1` projected-resource row schema exposes
  `effective_activity_count`, `ignored_activity_count`, and
  `ignored_activity_ids`.
- [x] Executable validation rejects malformed counts and malformed ignored activity
  IDs for the newly exposed fields.
- [x] Focused schema tests assert row schema shape and representative invalid
  values.
- [x] Checked-in schemas and bundle are refreshed.
- [x] Focused schema tests, schema export tests, schema lint, generated-schema
  spot-checks, and whitespace checks pass.
- [x] Read-only review finds no must-fix issues.
- [x] Slice-owned files only are committed and pushed.

Tests run:
- `mix format lib/orbital_dynamics/schema.ex test/orbital_dynamics/schema_test.exs`
- `mix test test/orbital_dynamics/schema_test.exs:19622 test/orbital_dynamics/schema_test.exs:24508`
- `MIX_OS_CONCURRENCY_LOCK=0 mix orbital_dynamics.schema.export --all --directory schemas --output schemas/orbital_dynamics.schema_bundle.v1.json`
- `jq -e` spot-check for projected-resource effective/ignored activity fields
  in `schemas/resource_projection_report.v1.schema.json`
- `git diff --check -- . ':!.gitignore'`
- `mix test test/mix/tasks/orbital_dynamics.schema.export_test.exs`
- `mix test test/orbital_dynamics/schema_test.exs`
- `mix orbital_dynamics.schema.lint --all`
- Read-only reviewer reran `git diff --check -- . ':!.gitignore'`,
  `mix test test/orbital_dynamics/schema_test.exs:19622 test/orbital_dynamics/schema_test.exs:24508`,
  fixture lint for `study_results/resource_projection_report_v1.json`,
  generated-schema `jq -e` checks, and ad hoc malformed count/ID/count-mismatch
  validation checks, and reported no must-fix findings.

Last completed implementation commit:
`731a22e4ec678d5d111b21cf09c0acca4297e16d` pushed to `origin/main`.

Last ledger correction commit:
Pending this ledger-only correction.

Next candidate:
Continue splitting `resource_projection_report.v1` `projected_resources` gaps:
battery quantities/state-of-charge, policy approval evidence, and
storage/downlink pressure quantities.

Blocked:
No.

Notes:
`.gitignore` still has an unrelated pre-existing local scratch-ignore change and
is not part of this slice. Treat current files as authoritative and do not
revert unrelated changes.
