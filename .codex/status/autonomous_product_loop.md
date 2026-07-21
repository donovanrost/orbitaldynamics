# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Register and fixture the atmospheric-drag numerical contract.

Status:
Implemented, parent-reviewed, and verified. Publish pending.

Why this slice:
The standalone evaluator is public and deterministic, but it is not yet a
validation-registry model and has no curated tolerance-backed reference fixture.
Adding propagation before that evidence would couple a new force into trajectory
artifacts without the project-standard model acceptance baseline.

Files changed:
- `lib/orbital_dynamics/validation/registry.ex`
- `lib/orbital_dynamics/validation/reference_fixtures/orbital.ex`
- `test/support/validation/orbital_reference_fixtures.ex`
- `test/orbital_dynamics/validation/orbital_reference_fixture_test.exs`
- `test/orbital_dynamics/validation/core_policy_test.exs`
- `test/orbital_dynamics/validation_test.exs`
- `schemas/candidate_refresh.v1.schema.json`
- `schemas/model_acceptance_report.v1.schema.json`
- `schemas/orbital_dynamics.schema_bundle.v1.json`
- `schemas/validation_record.v1.schema.json`
- `schemas/validation_safety_case_summary.v1.schema.json`
- `study_results/validation_reference_fixtures.json`
- `docs/feature_set/capability_map/03_propagation_and_force_models.md`
- `docs/feature_set/capability_map/18_validation_and_verification.md`
- `.codex/status/autonomous_product_loop.md`

Behavior changed:
`force_model.atmospheric_drag` now declares the evaluator's covered regime,
density/relative-velocity/acceleration tolerances, evidence, implementation,
educational level, and exact module-owned limits. Validation can resolve it by
stable ID or implementation module. Model acceptance routes it to review for
analysis use instead of treating it as unknown or accepted.

Public proof:
The fixture observation helper calls public
`OrbitalDynamics.atmospheric_drag_acceleration/4` for the curated 400 km case.
Fixture verification checks density, mass, co-rotation and relative velocities,
drag vector/magnitude, provider IDs, and model-limit count. A stale zero
acceleration magnitude fails the tolerance-backed check.

Docs read/changed:
- Read `docs/feature_set/capability_map/03_propagation_and_force_models.md`.
- Read `docs/feature_set/capability_map/18_validation_and_verification.md`.
- Read `docs/feature_set/definition_of_feature_complete.md`.

Verification:
- Registry/public-facade fixture/core-policy set: `21 passed`.
- Aggregate validation-report/schema regression set: `22 passed`.
- Schema and validation directories: `364 passed`.
- First full-suite run: `3456/3457 passed`; the sole failure identified stale
  checked-in JSON Schema exports after the new registry record.
- Schema-export/public-facade/core regression set after canonical export:
  `20 passed`.
- Final full `mix test --timeout 180000`: `3457 passed`.
- Changed Elixir files are formatted; `git diff --check` passes.

Artifact regeneration:
`study_results/validation_reference_fixtures.json` was regenerated through the
public drag facade and public validation-reference report builder. Canonical
comparison after removing the new report and restoring count 195 is exact to
`HEAD`; the only semantic change is the passing 196th drag fixture report.
The canonical all-contract schema exporter regenerated the five checked-in
schemas that embed validation-registry records.

Level 6 pillar advanced:
Validation baselines and tolerances for numerical force-model behavior.

Parent review:
No must-fix findings. The force model resolves independently from propagator IDs,
preserves its exact module-owned limits in schema validation, and remains
educational/review-required for analysis. The reference case is labeled as an
internal single-state regression rather than external truth. Sidecar delegation
remains unavailable under the active runtime policy, so the parent performed
review and publish checks.

Previous published slice:
- `bef573b3` Add atmospheric drag evaluator (`3456 passed`).

Current publish:
- Commit pending.

Remaining maturity gaps:
- Continue contact/resource/readiness selection only where canonical artifacts
  expose unambiguous blocking evidence.
- Continue branch-local realized-feedback depth where public replay preserves a
  decision-safe signal.
- Continue deeper numerical/backend and resource-model maturity separately.

Blocked:
Not blocked.
