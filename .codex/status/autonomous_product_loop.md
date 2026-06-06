# Autonomous Product Loop Status

Current slice:
Expose resource summary activity-type arrays and precondition row values in JSON
Schema.

Status:
Implemented, locally verified, reviewed clean, committed, and pushed.
Fixture/runtime visibility discovery showed `resource_summary.v1` artifacts
already validate `suppressed_activity_types` and `incompatible_activity_types`
as string arrays, but the standalone exported JSON Schema did not expose those
top-level fields. Timeline activity precondition summary fixtures also emit
optional precondition row `value` fields from the runtime precondition builder,
while the shared precondition row schema only named `type`, `status`, `field`,
and `reason`.

Why this matters:
Cadence-facing consumers need generated schema visibility to distinguish
activity types suppressed by resource state from types incompatible with current
resource state, and precondition handoff consumers need to see the row value
that identifies the blocking dimension or activity type. The executable
validators already accept these fields, so this slice aligns exported schemas
with existing runtime artifacts instead of changing behavior.

Likely files:
- `.codex/status/autonomous_product_loop.md`
- `lib/orbital_dynamics/schema.ex`
- `schemas/resource_summary.v1.schema.json`
- `schemas/timeline_activity_precondition_summary.v1.schema.json`
- generated schemas embedding the shared precondition row schema
- `schemas/orbital_dynamics.schema_bundle.v1.json`
- `test/orbital_dynamics/schema_test.exs`

Definition of done:
- `resource_summary.v1` JSON Schema exposes `suppressed_activity_types` and
  `incompatible_activity_types` as arrays of strings.
- Shared precondition row schema exposes optional `value` as a scalar compatible
  with current runtime rows.
- Focused schema tests assert the new schema-visible fields.
- Checked-in schemas and bundle are refreshed.
- Focused schema tests, relevant validator/runtime tests, schema export tests,
  schema lint, generated-schema spot-checks, and whitespace checks pass.
- Read-only review finds no must-fix issues.
- Slice-owned files only are committed and pushed.

Tests run:
- `mix format lib/orbital_dynamics/schema.ex test/orbital_dynamics/schema_test.exs`
- `mix test test/orbital_dynamics/schema_test.exs:987 test/orbital_dynamics/schema_test.exs:8880 test/orbital_dynamics/schema_test.exs:23173`
- `mix test test/orbital_dynamics/mission_plan/activity_test.exs:843`
- `MIX_OS_CONCURRENCY_LOCK=0 mix orbital_dynamics.schema.export --all --directory schemas --output schemas/orbital_dynamics.schema_bundle.v1.json`
- `jq` spot-checks for `resource_summary.v1` activity-type arrays and
  `timeline_activity_precondition_summary.v1`/review/import precondition
  `value` schema.
- `mix test test/orbital_dynamics/schema_test.exs`
- `mix test test/mix/tasks/orbital_dynamics.schema.export_test.exs`
- `mix orbital_dynamics.schema.lint --all`
- `git diff --check -- . ':!.gitignore'`
- `slice_reviewer`: no must-fix findings. Residual risk noted that `value`
  intentionally excludes `null`, arrays, and objects; accepted for current
  scalar precondition producers.
- `git_slice_publisher`: committed and pushed.

Last completed implementation commit:
`15d7ae21f37c344eb68f0d34a6ea2d0bd4d25587` pushed to `origin/main`.

Last ledger correction commit:
Pending.

Next candidate:
After this slice, continue fixture/schema visibility discovery. Known remaining
larger candidate: `timeline_lifecycle_state_summary.v1` row schema visibility.

Blocked:
No.

Notes:
`.gitignore` still has an unrelated pre-existing local scratch-ignore change and
is not part of this slice. Treat current files as authoritative and do not
revert unrelated changes.
