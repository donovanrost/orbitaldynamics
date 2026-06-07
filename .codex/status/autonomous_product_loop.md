# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Subsystem storage model capability record.

Status:
Implemented, verified, reviewed, committed, and pushed.

Files changed:
- `.codex/status/autonomous_product_loop.md`
- `lib/orbital_dynamics/subsystem_model.ex`
- `lib/orbital_dynamics.ex`
- `test/orbital_dynamics/schema_test.exs`
- `test/orbital_dynamics/capabilities_test.exs`
- `study_results/subsystem_model_capability_storage_v1.json`
- `study_results/capability_catalog_v1.json`
- `schemas/subsystem_model_capability.v1.schema.json`
- `schemas/orbital_dynamics.schema_bundle.v1.json`
- `docs/feature_set/capability_map/06_spacecraft_and_payload_modeling.md`
- `docs/feature_set/current_capability_snapshot.md`
- `docs/mission_planning/high_fidelity/16_near_term_planning_candidates.md`

Slice-selection note:
Selected slice:
Add a second built-in `subsystem_model_capability.v1` record for planning-grade
onboard data storage, plus a public facade and fixture/export/doc updates.

Why this slice:
The previous slice established the subsystem capability family with a battery
record. Resource projection also already exposes storage production/downlink
roll-forward behavior from selected activities and resource summaries. Adding a
storage-model capability record gives that existing storage evidence the same
explicit model identity/provenance/fidelity boundary without introducing full
recorder simulation or spacecraft-model composition.

Level 6 pillar advanced:
Resource-simulation model contracts and Cadence-facing setup fidelity.

Implementation notes:
- Added a built-in planning-grade data-recorder storage-buffer capability
  record in deterministic order after the battery energy-storage record.
- Added `OrbitalDynamics.data_storage_buffer_model/1`.
- Runtime and schema tests now validate the storage record, checked-in fixture,
  and exported known-limit const alongside the battery record.
- Refreshed `schemas/subsystem_model_capability.v1.schema.json`,
  `schemas/orbital_dynamics.schema_bundle.v1.json`, and
  `study_results/capability_catalog_v1.json`.
- Updated docs to state the subsystem contract foothold now covers battery and
  data-recorder storage while still excluding recorder partition, deletion,
  latency, full spacecraft configuration, and propagated subsystem state.

Tests run:
- `MIX_OS_CONCURRENCY_LOCK=0 mix orbital_dynamics.schema.export --all --directory schemas --output schemas/orbital_dynamics.schema_bundle.v1.json`
- `mix orbital_dynamics.capabilities --format json --output study_results/capability_catalog_v1.json`
- `mix format lib/orbital_dynamics/subsystem_model.ex lib/orbital_dynamics.ex test/orbital_dynamics/capabilities_test.exs test/orbital_dynamics/schema_test.exs`
- `mix test test/orbital_dynamics/capabilities_test.exs test/orbital_dynamics/schema_test.exs:327 test/orbital_dynamics/schema_test.exs:27393 test/orbital_dynamics/schema_test.exs:30357 test/mix/tasks/orbital_dynamics.schema.export_test.exs`
- `mix orbital_dynamics.schema.lint --all`
- `git diff --check`

Docs/artifacts changed:
- Added `study_results/subsystem_model_capability_storage_v1.json`.
- Refreshed checked-in subsystem JSON Schema, schema bundle, and capability
  catalog fixture.
- Updated spacecraft/resource capability map, current capability snapshot, and
  high-fidelity near-term planning candidates.

Review:
- Read-only reviewer Jason found one publish blocker: the new storage fixture
  was still untracked at review time.
- Fixed by including `study_results/subsystem_model_capability_storage_v1.json`
  in the slice staging set.
- Jason found no code blockers; runtime order, facade, validation consistency,
  schema export consts, catalog refresh, docs, and focused tests were
  consistent.

Remaining maturity gaps:
- Full `spacecraft_model.v1` and executable subsystem state propagation remain
  out of scope for this slice.
- External ICD-derived subsystem calibration and validation baselines remain
  future work.

Last commit:
`6d51b175c3ecf852c40e1795864da44be288cdee` pushed to `origin/main` for
Subsystem storage model capability record.

Next candidate:
After this slice, continue from the live guide/status and prefer another narrow
resource-simulation contract gap before expanding into full spacecraft models.

Unrelated local changes:
- `.gitignore` has an unrelated pre-existing local scratch-ignore change and is
  not part of the completed slices.

Blocked:
No.
