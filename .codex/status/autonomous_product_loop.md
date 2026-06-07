# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Subsystem model capability contract foothold.

Status:
Implemented, verified, reviewed, committed, and pushed.

Files changed:
- `.codex/status/autonomous_product_loop.md`
- `lib/orbital_dynamics/subsystem_model.ex`
- `lib/orbital_dynamics.ex`
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/validation.ex`
- `test/orbital_dynamics/schema_test.exs`
- `test/orbital_dynamics/capabilities_test.exs`
- `test/orbital_dynamics/validation_test.exs`
- `test/mix/tasks/orbital_dynamics.schema.export_test.exs`
- `study_results/subsystem_model_capability_v1.json`
- `study_results/capability_catalog_v1.json`
- `study_results/schema_migration_report_v1.json`
- `schemas/subsystem_model_capability.v1.schema.json`
- `schemas/orbital_dynamics.schema_bundle.v1.json`
- `docs/feature_set/capability_map/06_spacecraft_and_payload_modeling.md`
- `docs/feature_set/current_capability_snapshot.md`
- `docs/mission_planning/high_fidelity/16_near_term_planning_candidates.md`

Slice-selection note:
Selected slice:
Add a narrow `subsystem_model_capability.v1` artifact family with a public
facade, executable schema validation, checked-in JSON Schema export, capability
catalog exposure, and one representative battery energy-storage capability
record.

Why this slice:
High-fidelity planning docs identify explicit spacecraft/subsystem model
contracts as the first useful resource-simulation foothold. Environment model
capability records already provide the adjacent pattern; adding the subsystem
side gives downstream resource projection a schema-validated place to declare
model identity, provenance, fidelity, parameters, and known limits without
building the full spacecraft model in this slice.

Level 6 pillar advanced:
Resource-simulation model contracts and Cadence-facing setup fidelity.

Implementation notes:
- Added `OrbitalDynamics.SubsystemModel` with a built-in planning-grade
  battery energy-storage capability record.
- Added public facades:
  `OrbitalDynamics.subsystem_model_capabilities/0`,
  `OrbitalDynamics.battery_energy_storage_model/1`, and
  `OrbitalDynamics.validate_subsystem_model_capability/1`.
- Registered `subsystem_model_capability.v1` in the executable schema registry,
  JSON Schema export path, capability catalog, and validation fixture counts.
- Runtime validation now rejects unstable IDs and malformed string scalar fields
  consistently with executable schema validation.
- Refreshed checked-in schema exports, capability catalog, schema-migration
  fixture, and new subsystem capability fixture.
- Updated docs to mark the subsystem-model contract as an implemented foothold
  while keeping full spacecraft models and propagated subsystem simulation out
  of scope.

Tests run:
- `MIX_OS_CONCURRENCY_LOCK=0 mix orbital_dynamics.schema.export --all --directory schemas --output schemas/orbital_dynamics.schema_bundle.v1.json`
- `mix orbital_dynamics.capabilities --format json --output study_results/capability_catalog_v1.json`
- `mix run -e 'write = fn path, artifact -> json = artifact |> :json.encode() |> IO.iodata_to_binary(); File.write!(path, json <> "\n") end; deprecated = OrbitalDynamics.Validation.schema_migration_report(deprecated_contracts: %{"campaign_plan.v1" => "campaign_strategy.v3"}); write.("study_results/schema_migration_report_v1.json", deprecated)'`
- `mix format lib/orbital_dynamics/subsystem_model.ex lib/orbital_dynamics.ex lib/orbital_dynamics/schema.ex lib/orbital_dynamics/validation.ex test/orbital_dynamics/capabilities_test.exs test/orbital_dynamics/schema_test.exs test/orbital_dynamics/validation_test.exs test/mix/tasks/orbital_dynamics.schema.export_test.exs`
- `mix test test/orbital_dynamics/capabilities_test.exs test/orbital_dynamics/schema_test.exs:305 test/orbital_dynamics/schema_test.exs:327 test/orbital_dynamics/schema_test.exs:27393 test/orbital_dynamics/schema_test.exs:29976 test/orbital_dynamics/schema_test.exs:30357 test/mix/tasks/orbital_dynamics.schema.export_test.exs test/orbital_dynamics/validation_test.exs:48 test/orbital_dynamics/validation_test.exs:4322 test/orbital_dynamics/validation_test.exs:10857 test/orbital_dynamics/validation_test.exs:10942`
- `mix orbital_dynamics.schema.lint --all`
- `git diff --check`

Docs/artifacts changed:
- Added `study_results/subsystem_model_capability_v1.json`.
- Added `schemas/subsystem_model_capability.v1.schema.json`.
- Refreshed `schemas/orbital_dynamics.schema_bundle.v1.json`,
  `study_results/capability_catalog_v1.json`, and
  `study_results/schema_migration_report_v1.json`.
- Updated spacecraft/resource capability map, current capability snapshot, and
  high-fidelity near-term planning candidates.

Review:
- Read-only reviewer Hegel found one blocker: the public subsystem capability
  validator accepted schema-invalid records with unstable IDs or non-string
  scalar fields.
- Fixed by adding stable-ID and scalar string checks in
  `OrbitalDynamics.SubsystemModel.validate_capability/1` plus regression tests
  covering invalid `id`, `subsystem`, `model`, `source`, and `fidelity_tier`.
- Hegel found no other subsystem blockers. The broader reference-fixture report
  still has unrelated pre-existing observation drift outside this slice.

Remaining maturity gaps:
- Full `spacecraft_model.v1` and executable subsystem state propagation remain
  out of scope for this slice.
- External ICD-derived subsystem calibration and validation baselines remain
  future work.

Last commit:
`0dedd1f44b348522078486ca24f9a07475ff770f` pushed to `origin/main` for
Subsystem model capability contract foothold.

Next candidate:
After this slice, continue from the live guide/status and prefer another narrow
resource-simulation contract gap before expanding into full spacecraft models.

Unrelated local changes:
- `.gitignore` has an unrelated pre-existing local scratch-ignore change and is
  not part of the completed slices.

Blocked:
No.
