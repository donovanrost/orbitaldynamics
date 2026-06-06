# Autonomous Product Loop Status

Current slice:
Expose resource-projection row availability and pressure-status schemas.

Status:
Implemented, locally verified, read-only reviewed clean, committed, and pushed.

Discovery:
Broad fixture/schema visibility discovery shows the larger remaining row gap is
`resource_projection_report.v1` `projected_resources`. Split the first bounded
subset to row-level metadata emitted by both projection fixtures:
`payload_available`, `antenna_available`, `resource_trust_boundary_status`,
`resource_pressure_status`, `resource_pressure_types`, and
`resource_provenance`.

Why this matters:
Projected-resource rows are the per-spacecraft review/import summary for
storage/downlink/resource pressure. Availability flags, trust-boundary routing,
pressure status/type classifications, and provenance are adapter-facing metadata
that should be schema-visible before tackling the larger battery, ignored-flow,
and policy-evidence row fields.

Likely files:
- `.codex/status/autonomous_product_loop.md`
- `lib/orbital_dynamics/schema.ex`
- generated schemas embedding `resource_projection_row_json_schema/0`
- `schemas/orbital_dynamics.schema_bundle.v1.json`
- `test/orbital_dynamics/schema_test.exs`

Definition of done:
- [x] `resource_projection_report.v1` projected-resource row schema exposes
  availability flags, trust-boundary status, pressure status/type, and
  provenance fields.
- [x] Executable validation rejects malformed booleans, strings, lists, and
  provenance objects for the newly exposed fields.
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
- `jq -e` spot-check for projected-resource metadata fields in
  `schemas/resource_projection_report.v1.schema.json`
- `mix test test/mix/tasks/orbital_dynamics.schema.export_test.exs`
- `mix orbital_dynamics.schema.lint --all`
- `git diff --check -- . ':!.gitignore'`
- `mix test test/orbital_dynamics/schema_test.exs`
- Read-only reviewer reran `git diff --check -- . ':!.gitignore'`,
  `mix test test/orbital_dynamics/schema_test.exs:19622 test/orbital_dynamics/schema_test.exs:24508`,
  generated-schema `jq -e` checks, and fixture lint for both resource-projection
  fixtures, and reported no must-fix findings.

Last completed implementation commit:
`0ec3eaa78d9a9f56ba1f2315d552a182468dae9b` pushed to `origin/main`.

Last ledger correction commit:
Pending this ledger-only correction.

Next candidate:
Continue splitting `resource_projection_report.v1` `projected_resources` gaps:
battery quantities/state-of-charge, ignored-activity routing, policy approval
evidence, and storage/downlink pressure quantities.

Blocked:
No.

Notes:
`.gitignore` still has an unrelated pre-existing local scratch-ignore change and
is not part of this slice. Treat current files as authoritative and do not
revert unrelated changes.
