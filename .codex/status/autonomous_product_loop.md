# Autonomous Product Loop Status

Current slice:
Advertise activity template helpers through the public capability catalog.

Status:
Implemented, verified, and read-only reviewed.

What changed:
- Added `planning.activity_templates` to `OrbitalDynamics.capability_catalog/0`.
- The entry advertises `activity_template.v1`, validation level, supported
  activity types, template IDs/count, public facades
  `activity_templates/0`, `activity_template/1`, and `activity_from_template/2`,
  normalized timeline activity output, transition-application path, known
  limits, and no-mutation assumptions.
- Extended public capability tests to pin the discovery entry and let the
  existing public-facade export test cover the newly advertised helpers.
- Regenerated `study_results/capability_catalog_v1.json`.
- Updated the curated capability-catalog validation reference expected
  `planning_capability_count` from 4 to 5 and refreshed the matching checked-in
  `study_results/validation_reference_fixtures.json` check.

Verification:
- `mix test test/orbital_dynamics/capabilities_test.exs` -> 6 passed.
- `mix test test/orbital_dynamics/capabilities_test.exs test/mix/tasks/orbital_dynamics.capabilities_test.exs`
  -> 10 passed.
- `mix test test/orbital_dynamics/schema_test.exs:189 test/orbital_dynamics/validation_test.exs:4042 test/orbital_dynamics/validation_test.exs:10693 test/orbital_dynamics/validation_test.exs:11684`
  -> 3 passed, 253 excluded.
- `mix test test/orbital_dynamics/schema_test.exs:11335` -> 1 passed, 120 excluded.
- `mix orbital_dynamics.schema.lint --input study_results/capability_catalog_v1.json` -> pass.
- `mix orbital_dynamics.schema.lint --input study_results/validation_reference_fixtures.json` -> pass.
- Reviewer confirmed `study_results/capability_catalog_v1.json` matches
  `OrbitalDynamics.capability_catalog_artifact/0`.
- `git diff --check` -> pass.

Read-only review:
Sidecar `019e9c86-dbd5-70b1-a12a-2830b870a563` reported no findings.

Implementation commit:
`edbfa97c7b296717daec09000db945f3e4d6dbdd` pushed to `origin/main`.

Last completed implementation commit:
`edbfa97c7b296717daec09000db945f3e4d6dbdd` pushed to `origin/main`.

Last ledger correction commit:
`5724cdf6dd60507bd3231baadd5ffe17d3806d2a` pushed to `origin/main`.

Next candidate:
Continue deeper into typed activity state/dependency validation after the
template path is discoverable.

Blocked:
No.

Notes:
`.gitignore` still has an unrelated pre-existing local scratch-ignore change and
is not part of this slice. Treat current files as authoritative and do not
revert unrelated changes.
