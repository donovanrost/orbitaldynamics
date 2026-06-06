# Autonomous Product Loop Status

Current slice:
Expose a small public `activity_template.v1` catalog helper.

Status:
Completed and pushed.

What changed:
- Added `OrbitalDynamics.activity_templates/0`, returning deterministic
  JSON-facing `activity_template.v1` artifacts for baseline supported activity
  types: observe, downlink, command, health check, slew, and impulsive burn
  as the maneuver template.
- Added `OrbitalDynamics.activity_template/1` lookup by template id or
  activity type, returning `{:ok, template}` or `:error`.
- Kept the helper artifact-only: no schedule mutation, no planner execution
  changes, no transition engine changes, and no generated capability-catalog
  refresh.
- Preserved the checked-in `study_results/activity_template_v1.json` observe
  fixture by decoded map equality against the first helper-produced template.
- Added focused public facade tests for deterministic IDs, supported activity
  types, default-field declarations, executable schema validation, fixture
  equality, and unknown/non-binary lookup paths.

Verification:
- `mix test test/orbital_dynamics/capabilities_test.exs` -> 5 passed.
- `mix test test/orbital_dynamics/schema_test.exs:58` -> 1 passed.
- `mix orbital_dynamics.schema.lint --input study_results/activity_template_v1.json` -> pass.
- `git diff --check` -> pass.

Read-only review:
- Sidecar `019e9c63-ed9b-7bb3-9856-61f816723f81` reported no findings.
- Reviewer also reran the focused facade test, single-artifact lint, and scoped
  whitespace check.

Implementation commit:
`c58367c010f84e9c6e933bbbb0faeedc37904c50` pushed to `origin/main`.

Last ledger correction commit:
Pending this ledger-only correction.

Next candidate:
Validate one transition path that consumes a template without mutating
schedules.

Blocked:
No.

Notes:
`.gitignore` still has an unrelated pre-existing local scratch-ignore change and
is not part of this slice. Treat current files as authoritative and do not
revert unrelated changes.
