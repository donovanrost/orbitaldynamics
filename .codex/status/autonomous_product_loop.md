# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Timeline preservation assumption schema pinning.

Status:
Implemented, reviewed, committed, and ready to push.

Slice-selection note:
Selected slice:
Pin the fixed `assumptions` maps for `timeline_preservation_report.v1` and
`timeline_preservation_status.v1` in JSON Schema export.

Why this slice:
Timeline preservation artifacts already emit and runtime-validate the
artifact-only no-schedule-mutation boundary plus a scope-specific preservation
meaning. The exported schemas still expose `assumptions` as a loose object, so
schema-only handoffs cannot detect stale preservation boundary metadata.

Level 6 pillar:
Durable schema-versioned timeline artifacts and Cadence-facing adapter safety.

Current evidence gap:
Runtime validation rejects stale preservation `execution_boundary` and `scope`
assumptions, but the exported preservation schemas do not advertise exact
constants for those fields.

Docs read:
- `docs/artifacts/field_families/mission_activities.md`
- `docs/mission_planning/high_fidelity/04_plan_structure_and_lifecycle.md`

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `test/orbital_dynamics/schema_test.exs`
- `schemas/timeline_preservation_report.v1.schema.json`
- `schemas/timeline_preservation_status.v1.schema.json`
- `schemas/orbital_dynamics.schema_bundle.v1.json`
- `docs/artifacts/field_families/mission_activities.md`

Likely tests:
- `mix test test/orbital_dynamics/schema_test.exs:<preservation schema tests>`
- `MIX_OS_CONCURRENCY_LOCK=0 mix orbital_dynamics.schema.export --all --directory schemas --output schemas/orbital_dynamics.schema_bundle.v1.json`
- `mix test test/mix/tasks/orbital_dynamics.schema.export_test.exs`
- `mix orbital_dynamics.schema.lint --all`
- `git diff --check`

Definition of done:
- Preservation report/status schemas export exact assumption constants for the
  runtime-enforced boundary and scope fields.
- Tests prove schema export matches the runtime assumptions and stale runtime
  assumptions are rejected.
- Checked-in schema exports are refreshed.
- Focused tests, schema lint, and whitespace checks pass.

Current implementation:
- `timeline_preservation_report.v1` schema now requires and pins
  `execution_boundary` and the report preservation `scope`.
- `timeline_preservation_status.v1` schema now requires and pins
  `execution_boundary` and the single-activity preservation `scope`.
- Schema tests assert both exported assumption schemas and runtime rejection for
  stale report/status scopes.
- Checked-in preservation schema exports and the schema bundle were refreshed.
- Mission-activities docs now mention schema-pinned preservation assumptions.

Verification:
- `mix format lib/orbital_dynamics/schema.ex test/orbital_dynamics/schema_test.exs`
- `MIX_OS_CONCURRENCY_LOCK=0 mix orbital_dynamics.schema.export --all --directory schemas --output schemas/orbital_dynamics.schema_bundle.v1.json`
- `mix test test/orbital_dynamics/schema_test.exs:12039 test/orbital_dynamics/schema_test.exs:12123 test/orbital_dynamics/schema_test.exs:12297`
- `mix test test/mix/tasks/orbital_dynamics.schema.export_test.exs`
- `mix orbital_dynamics.schema.lint --all`
- `git diff --check`

Review:
- Read-only sidecar review found no issues for the preservation assumption
  schema pinning slice. Reviewer also compared the generated preservation
  schemas and bundle against live exporter output.

Product commit:
- `cc730fd` (`Pin timeline preservation assumptions`)

Previous pushed slice:
Full timeline activity-state no-authority assumption schema pinning landed in
product commit `f67c5ec` and final pushed ledger commit `5f90203`, with local
and `origin/main` verified at `5f902032963b479399f0537529da47ca7d6d983e`.

Unrelated local changes:
- `.gitignore` has an unrelated pre-existing local scratch-ignore change and is
  not part of this slice.

Blocked:
No.
