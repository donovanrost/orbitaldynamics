# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Add an executable, provider-backed atmospheric-drag acceleration model.

Status:
Implemented, parent-reviewed, and verified. Publish pending.

Why this slice:
Spacecraft mass, drag area, and drag coefficient are modeled, and the validated
exponential-atmosphere provider returns deterministic density, but no executable
force-model behavior joins those inputs. A standalone evaluator is the smallest
safe step before coupling drag into trajectory propagation and artifacts.

Files changed:
- `lib/orbital_dynamics/force_models/atmospheric_drag.ex`
- `lib/orbital_dynamics.ex`
- `lib/orbital_dynamics/environment/exponential_atmosphere_provider.ex`
- `lib/orbital_dynamics/spacecraft.ex`
- `test/orbital_dynamics/force_models/atmospheric_drag_test.exs`
- `test/orbital_dynamics/capabilities_test.exs`
- `docs/feature_set/capability_map/03_propagation_and_force_models.md`
- `docs/feature_set/capability_map/04_environment_and_ephemeris_providers.md`
- `docs/feature_set/capability_map/06_spacecraft_and_payload_modeling.md`
- `.codex/status/autonomous_product_loop.md`

Behavior changed:
`OrbitalDynamics.atmospheric_drag_acceleration/4` now evaluates one Earth/J2000
state using spacecraft mass, drag area/coefficient, a request-fit validated
atmosphere provider, and constant-rate Earth co-rotation. It returns the
atmosphere-relative velocity, acceleration in km/s2, full density product,
provider IDs/models, units, assumptions, and exact model limits. It does not
propagate the state.

Public proof:
The facade regression evaluates a 400 km state, proves drag opposes the
co-rotation-relative velocity, checks the explicit SI conversion against the
closed-form magnitude, verifies configured zero-density provider parameters,
and exercises input/provider rejection boundaries. The schema-valid public
capability catalog advertises the model and facade.

Docs read/changed:
- Read `docs/feature_set/capability_map/03_propagation_and_force_models.md`.
- Read `docs/feature_set/capability_map/04_environment_and_ephemeris_providers.md`.
- Read `docs/feature_set/capability_map/06_spacecraft_and_payload_modeling.md`.

Verification:
- Force-model/environment/capability set: `26 passed`.
- Force-model/propagator/provider/schema-capability set: `64 passed`.
- Schema and validation directories: `363 passed`.
- Full `mix test --timeout 180000`: `3456 passed`.
- Changed Elixir files are formatted; `git diff --check` passes.

Artifact regeneration:
Not expected; this is a deterministic public numerical API and capability
surface, not a persisted study-result change.

Level 6 pillar advanced:
High-fidelity subsystem contracts and explicit force-model assumptions.

Parent review:
No must-fix findings. The acceleration uses atmosphere-relative velocity from
declared constant Earth co-rotation and the explicit SI-to-km/s2 conversion;
provider product identity/model must match its validated capability. Malformed
state/spacecraft inputs return errors, zero density/coefficient remains a valid
zero-acceleration case, and every surface preserves the standalone/no-current-
propagator boundary. Sidecar delegation remains unavailable under the active
runtime policy, so the parent performed review and publish checks.

Previous published slice:
- `f8f6be7f` Expose backend acceptance summaries (`3452 passed`).

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
