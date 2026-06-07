# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Resource flow subsystem model capability references.

Status:
Implemented, verified, and reviewed; ready to commit and push.

Files changed:
- `.codex/status/autonomous_product_loop.md`
- `lib/orbital_dynamics/resource_projection.ex`
- `lib/orbital_dynamics/resource_summary.ex`
- `test/orbital_dynamics/resource_projection_test.exs`
- `test/orbital_dynamics/resource_summary_test.exs`
- `study_results/capability_catalog_v1.json`
- `docs/feature_set/capability_map/06_spacecraft_and_payload_modeling.md`
- `docs/mission_planning/high_fidelity/01_digital_twin_and_subsystem_models.md`

Slice-selection note:
Selected slice:
Advertise the built-in battery and storage `subsystem_model_capability.v1`
records from resource projection and resource-summary roll-forward capability
metadata.

Why this slice:
The subsystem capability family now defines battery and storage planning-grade
model records, but existing resource-flow discovery still only lists aliases and
known limits. Advertising the exact subsystem model IDs from
`ResourceProjection.capabilities/0` and the `ResourceSummary` roll-forward
facade closes the discovery gap without changing projection math or artifact
schemas.

Level 6 pillar advanced:
Resource-simulation model contracts and Cadence-facing setup fidelity.

Implementation notes:
- `ResourceProjection.capabilities/0` now advertises
  `subsystem_model_capability.v1`, ordered battery/storage capability IDs, and
  a by-resource ID map.
- `ResourceSummary.capabilities/0` forwards the same roll-forward subsystem
  model metadata from `ResourceProjection.capabilities/0` instead of creating a
  second source of truth.
- Capability tests pin deterministic ID order and by-resource routing.
- Refreshed the checked-in capability catalog so discovery clients see the new
  resource-flow model references.
- Updated docs to explain that resource-flow evidence links to declarative
  subsystem model records without changing projection math or claiming
  continuous subsystem-state propagation.

Tests run:
- `mix orbital_dynamics.capabilities --format json --output study_results/capability_catalog_v1.json`
- `mix format lib/orbital_dynamics/resource_projection.ex lib/orbital_dynamics/resource_summary.ex test/orbital_dynamics/resource_projection_test.exs test/orbital_dynamics/resource_summary_test.exs`
- `mix test test/orbital_dynamics/resource_projection_test.exs test/orbital_dynamics/resource_summary_test.exs`
- `mix test test/orbital_dynamics/resource_projection_test.exs:5 test/orbital_dynamics/resource_summary_test.exs:5 test/orbital_dynamics/capabilities_test.exs test/orbital_dynamics/schema_test.exs:305`
- `mix orbital_dynamics.schema.lint --all`
- `git diff --check`

Docs/artifacts changed:
- Refreshed `study_results/capability_catalog_v1.json`.
- Updated spacecraft/resource capability map and digital-twin/subsystem model
  planning doc.

Review:
- Read-only reviewer Arendt found no blockers.
- Arendt confirmed deterministic ID ordering, alignment with
  `OrbitalDynamics.SubsystemModel`, ResourceSummary pass-through metadata,
  refreshed capability catalog, metadata-only scope, and the unrelated
  `.gitignore` remaining unstaged.

Remaining maturity gaps:
- Full `spacecraft_model.v1` and executable subsystem state propagation remain
  out of scope for this slice.
- External ICD-derived subsystem calibration and validation baselines remain
  future work.

Last commit:
`d133f0fb43090760ce5a55a9cde20cf065516d3b` pushed to `origin/main` for the
previous subsystem storage model capability handoff.

Next candidate:
After this slice, continue from the live guide/status and prefer another narrow
resource-simulation contract gap before expanding into full spacecraft models.

Unrelated local changes:
- `.gitignore` has an unrelated pre-existing local scratch-ignore change and is
  not part of the completed slices.

Blocked:
No.
