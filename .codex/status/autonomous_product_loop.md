# Autonomous Product Loop Status

Current slice:
ResourceSummary battery-generated-energy preservation.

Status:
Implemented with focused verification passing locally. `ResourceSummary`
normalizes optional summary-level `battery_energy_generated_wh` evidence, accepts
common generated-energy aliases such as `estimated_battery_energy_generated_wh`,
advertises the alias set through capabilities, preserves the field through
`to_map/1`, and validates it as an optional non-negative `resource_summary.v1`
schema field. Direct resource-projection summary sanitization now treats the
same field as a non-negative resource-summary input.

Files changed:
- `.codex/status/autonomous_product_loop.md`
- `docs/feature_set/capability_map/06_spacecraft_and_payload_modeling.md`
- `lib/orbital_dynamics/resource_projection.ex`
- `lib/orbital_dynamics/resource_summary.ex`
- `lib/orbital_dynamics/schema.ex`
- `schemas/orbital_dynamics.schema_bundle.v1.json`
- `schemas/resource_summary.v1.schema.json`
- `test/orbital_dynamics/resource_summary_test.exs`

Tests run:
- `mix format lib/orbital_dynamics/resource_summary.ex lib/orbital_dynamics/resource_projection.ex lib/orbital_dynamics/schema.ex test/orbital_dynamics/resource_summary_test.exs`
- `mix test test/orbital_dynamics/resource_summary_test.exs`
- `mix orbital_dynamics.schema.export --contract resource_summary.v1 --output schemas/resource_summary.v1.schema.json`
- `MIX_OS_CONCURRENCY_LOCK=0 mix orbital_dynamics.schema.export --all --directory schemas --output schemas/orbital_dynamics.schema_bundle.v1.json`
- `mix test test/orbital_dynamics/resource_projection_test.exs:250 test/orbital_dynamics/resource_projection_test.exs:1472 test/orbital_dynamics/schema_test.exs:990 test/orbital_dynamics/schema_test.exs:1117 test/orbital_dynamics/schema_test.exs:17241`
- `mix test test/orbital_dynamics/resource_projection_test.exs`
- `mix format lib/orbital_dynamics/schema.ex`
- `mix orbital_dynamics.schema.export --contract resource_summary.v1 --output schemas/resource_summary.v1.schema.json`
- `MIX_OS_CONCURRENCY_LOCK=0 mix orbital_dynamics.schema.export --all --directory schemas --output schemas/orbital_dynamics.schema_bundle.v1.json`
- `mix test test/orbital_dynamics/resource_summary_test.exs test/orbital_dynamics/schema_test.exs:990 test/orbital_dynamics/schema_test.exs:1117 test/orbital_dynamics/schema_test.exs:17241`
- `mix orbital_dynamics.schema.lint --all`
- `git diff --check`

Definition of done:
Summary-level generated battery-energy evidence survives ResourceSummary
normalization and artifact serialization, the executable and exported
`resource_summary.v1` contract accepts only non-negative values, direct
resource-projection summary validation rejects negative generated-energy inputs,
the public capability docs are updated, and focused ResourceSummary,
ResourceProjection, and schema tests pass.

Last completed/pushed commit before this slice:
`1973689` (`Replay station contention provider IDs`).

Next candidate:
Continue guide-backed resource/communications allocation work from queue item 2,
unless live inspection shows those slices are already complete and a
higher-priority queue item has the next concrete gap.

Blocked:
No.

Notes:
`.gitignore` still has an unrelated pre-existing local scratch-ignore change and
is not part of this slice. Treat current files as authoritative and do not
revert unrelated changes.
