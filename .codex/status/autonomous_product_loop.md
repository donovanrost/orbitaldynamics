# Autonomous Product Loop Status

Current slice:
Typed `MissionPlan.Activity` preserves declared `battery_energy_generated_wh`.

Status:
Implementation, docs, manifest schema, checked-in manifest schema export, and
focused verification are complete. `MissionPlan.Activity` now carries canonical
non-negative `battery_energy_generated_wh` through struct/type metadata,
capabilities, `from_map!` alias ingress, constructor validation, `to_map`, and
artifact/normalized activity-context egress. Study manifests now expose and load
the same field for mission-plan activities and candidate-refresh realized
activity inputs, with `minimum: 0.0` in exported manifest schema. This is
artifact-only resource evidence; it does not roll battery state, mutate
schedules, approve imports, reserve resources, or execute commands.

Files changed in this slice:
- `.codex/status/autonomous_product_loop.md`
- `docs/artifacts/field_families/mission_activities.md`
- `lib/orbital_dynamics/mission_plan/activity.ex`
- `lib/orbital_dynamics/study/manifest.ex`
- `schemas/study_manifest.v1.schema.json`
- `test/mix/tasks/orbital_dynamics.manifest.schema.export_test.exs`
- `test/orbital_dynamics/mission_plan/activity_test.exs`
- `test/orbital_dynamics/study/manifest_test.exs`

Verification:
- `mix format lib/orbital_dynamics/mission_plan/activity.ex lib/orbital_dynamics/study/manifest.ex test/orbital_dynamics/mission_plan/activity_test.exs test/orbital_dynamics/study/manifest_test.exs`
- `mix format test/orbital_dynamics/mission_plan/activity_test.exs test/orbital_dynamics/study/manifest_test.exs test/mix/tasks/orbital_dynamics.manifest.schema.export_test.exs`
- `mix orbital_dynamics.manifest.schema.export --output schemas/study_manifest.v1.schema.json`
- `mix test test/orbital_dynamics/mission_plan/activity_test.exs test/orbital_dynamics/study/manifest_test.exs --trace --seed 0`
- `mix test test/mix/tasks/orbital_dynamics.manifest.schema.export_test.exs --trace --seed 0`
- `mix test test/orbital_dynamics/mission_plan/activity_test.exs test/orbital_dynamics/study/manifest_test.exs test/mix/tasks/orbital_dynamics.manifest.schema.export_test.exs --trace --seed 0`
- `git diff --check`

Review/publish:
Reviewer found no must-fix issues. Suggested coverage gaps were resolved with
alias, manifest-negative, and export-task schema assertions. Publisher handoff
pending.

Last published slice:
`42b90c5ea816d600c307d3a5b320ec15a008c384` preserved battery generation
handoff context across timeline/feedback surfaces.

Next candidate:
After review and publish, re-read the guide/ledger/live worktree and continue
with the highest-priority unimplemented typed activity context or feedback
handoff field family before moving to lower-priority resource/quality slices.

Blocked:
No.

Notes:
Treat current files as authoritative and do not revert unrelated changes.
`.gitignore` has an unrelated pre-existing local scratch-ignore change and is
not part of this slice.
