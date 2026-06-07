# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Resource projection artifact subsystem capability assumptions.

Status:
Implemented, verified, reviewed, committed locally, and awaiting push.

Files changed:
- `.codex/status/autonomous_product_loop.md`
- `lib/orbital_dynamics/resource_projection.ex`
- `lib/orbital_dynamics/schema.ex`
- `test/orbital_dynamics/resource_projection_test.exs`
- `test/orbital_dynamics/schema_test.exs`
- `schemas/resource_projection_report.v1.schema.json`
- `schemas/resource_projection_flow_summary.v1.schema.json`
- `schemas/campaign_plan.v1.schema.json`
- `schemas/orbital_dynamics.schema_bundle.v1.json`
- `study_results/resource_projection_report_v1.json`
- `study_results/resource_projection_flow_summary_v1.json`
- `docs/feature_set/capability_map/06_spacecraft_and_payload_modeling.md`
- `docs/mission_planning/high_fidelity/01_digital_twin_and_subsystem_models.md`

Slice-selection note:
Selected slice:
Emit and validate the exact `subsystem_model_capability.v1` contract and
battery/storage capability IDs inside `resource_projection_report.v1` and
`resource_projection_flow_summary.v1` assumptions.

Why this slice:
The previous slice made resource-flow discovery metadata point at the built-in
battery and storage subsystem model records, but the emitted projection
artifacts still only describe their thin roll-forward assumptions in prose.
Putting the exact contract and IDs into artifact assumptions lets downstream
review/import adapters verify which declarative subsystem models were used
without changing projection math or claiming propagated subsystem state.

Level 6 pillar advanced:
Resource-simulation model contracts and Cadence-facing artifact traceability.

Implementation notes:
- `ResourceProjection.report/3` now emits additive subsystem capability
  assumptions naming `subsystem_model_capability.v1`, the ordered battery and
  storage capability IDs, and the IDs by resource.
- `ResourceProjection.flow_summary/1` emits the same assumptions through a
  shared helper so compact flow artifacts and full projection reports do not
  drift.
- `Schema.validate_artifact/1` keeps those assumptions optional for older
  artifacts, but rejects stale contract, ID list, or by-resource values when
  the fields are present.
- JSON Schema export now makes the optional assumptions schema-visible for
  `resource_projection_report.v1` and `resource_projection_flow_summary.v1`.
- The checked-in canonical report and flow-summary fixtures now carry the
  subsystem capability assumptions. The flow summary was regenerated from
  `OrbitalDynamics.resource_projection_flow_summary/1`.

Tests run:
- `mix format lib/orbital_dynamics/resource_projection.ex lib/orbital_dynamics/schema.ex test/orbital_dynamics/resource_projection_test.exs`
- `MIX_OS_CONCURRENCY_LOCK=0 mix orbital_dynamics.schema.export --all --directory schemas --output schemas/orbital_dynamics.schema_bundle.v1.json`
- `mix test test/orbital_dynamics/resource_projection_test.exs`
- `mix test test/orbital_dynamics/schema_test.exs:1697 test/orbital_dynamics/schema_test.exs:4438 test/orbital_dynamics/schema_test.exs:24601 test/mix/tasks/orbital_dynamics.schema.export_test.exs:5506`
- `mix orbital_dynamics.schema.lint --all`
- `mix test test/orbital_dynamics/validation_test.exs:9934 test/orbital_dynamics/validation_test.exs:10041`
- `mix test test/orbital_dynamics/resource_projection_test.exs test/orbital_dynamics/schema_test.exs:1697 test/orbital_dynamics/schema_test.exs:4438 test/orbital_dynamics/schema_test.exs:24601 test/mix/tasks/orbital_dynamics.schema.export_test.exs:5506 test/orbital_dynamics/validation_test.exs:9934 test/orbital_dynamics/validation_test.exs:10041`
- `git diff --check`

Docs/artifacts changed:
- Refreshed resource projection report/flow-summary schemas, campaign-plan
  nested schema, and the schema bundle.
- Refreshed `study_results/resource_projection_report_v1.json` and
  `study_results/resource_projection_flow_summary_v1.json`.
- Updated spacecraft/resource capability map and digital-twin/subsystem model
  planning doc.

Review:
- Read-only reviewer Poincare found one blocker: the canonical
  `study_results/resource_projection_report_v1.json` fixture still lacked the
  new generated assumptions. Fixed by updating the canonical report fixture,
  rerunning the flow-summary fixture generation, adding a by-resource stale
  assumption regression, and rerunning focused verification plus schema lint.
- Poincare rechecked the fixed slice and found no remaining blockers.

Remaining maturity gaps:
- Full `spacecraft_model.v1` and executable subsystem state propagation remain
  out of scope for this slice.
- External ICD-derived subsystem calibration and validation baselines remain
  future work.

Last commit:
`25dd9e79372d325385fb3e362b9dd1c4e2bc13f67` committed locally for Resource
projection artifact subsystem capability assumptions.

Next candidate:
After this slice, continue from the live guide/status and prefer another narrow
resource or communications allocation contract gap, especially one that exposes
reservation/allocation semantics without expanding into full spacecraft models.

Unrelated local changes:
- `.gitignore` has an unrelated pre-existing local scratch-ignore change and is
  not part of the completed slices.

Blocked:
No.
