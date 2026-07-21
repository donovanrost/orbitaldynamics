# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Add an opt-in scalar two-body plus atmospheric-drag propagator.

Status:
Implemented, parent-reviewed, and verified. Publish pending.

Why this slice:
The drag evaluator and its tolerance-backed registry fixture are now published,
but no trajectory path consumes the force. A separate opt-in propagator can add
the first dissipative trajectory behavior without changing established two-body
or J2 defaults.

Files changed:
- New `Propagators.TwoBodyDrag` implementation and regression test.
- Public capability catalog, force/environment/spacecraft boundaries, result
  artifact model limits, validation registry/model-acceptance checks, orbital
  fixtures, fixture helpers/tests, aggregate validation test, and generated
  artifacts.
- README, executive summary, capability-map docs 03/04/06/18, and the
  environment-policy contract reference.
- `.codex/status/autonomous_product_loop.md`.

Behavior changed:
`Propagators.TwoBodyDrag` now performs Earth/J2000-only fixed-step RK4 with
point-mass gravity plus validated provider-backed drag at every stage. It is
opt-in, supports aligned impulsive maneuvers, threads provider/state errors,
records exact ballistic/provider/model assumptions, and does not change existing
propagators. It is programmatic-only; JSON-manifest registration is deferred.

Public proof:
The public programmatic `Study` path drives a curated 400 km/600 s fixture whose
specific energy changes by `-3.377895765410699e-5 km2/s2`. Zero-density provider
parameters reproduce fixed-step two-body states exactly. `run_study/2` produces
a schema-valid result artifact with the combined force-model identity and exact
trajectory limits; a stale zero energy change fails fixture verification.

Docs read/changed:
- Read `docs/feature_set/capability_map/03_propagation_and_force_models.md`.
- Read/changed capability maps 03, 04, and 06 plus the environment-policy
  contract reference.
- Read `docs/feature_set/definition_of_feature_complete.md`.
- Read the propagator behavior, scalar two-body/J2 implementations, scenario,
  trajectory, public capability catalog, and study-manifest registry.

Verification:
- Propagator/provider/capability/backend-policy/fixture/artifact set: `61 passed`.
- Public Study/result-artifact propagator test: `6 passed`.
- Aggregate validation/schema/export set after regeneration: `5 passed`.
- Validation and schema directories: `370 passed`.
- Post-review propagator/core-policy set: `17 passed`.
- First full-suite run: `3464/3465 passed`; the sole failure was golden campaign
  drift from temporarily changing the established backend-tier description.
- Golden campaign/core-policy/propagator regression after restoring the
  established tier and leaving the new backend unclassified: `18 passed`.
- Final full `mix test --timeout 180000`: `3465 passed`.
- `mix compile --warnings-as-errors` passes.

Artifact regeneration:
The public validation-reference report builder regenerated the 197-report
aggregate with one new passing drag-trajectory report; the canonical schema
exporter updated the six registry/provider-embedded checked-in schemas.

Level 6 pillar advanced:
High-fidelity trajectory behavior with explicit provider-backed force models.

Parent review:
No remaining must-fix findings. Review found and fixed a malformed-list option
path that reached keyword access before validation. RK4 stages use the correct
half/full-step epochs; provider failures remain tagged errors; malformed scenario
state is rejected safely; model limits are deduplicated in result artifacts; and
the new backend remains custom/unclassified until dedicated comparison evidence
exists while model acceptance stays educational/review-required. Sidecar
delegation remains unavailable under the active runtime policy, so the parent
performed review and publish checks.

Previous published slice:
- `3f59a8d0` Register atmospheric drag validation (`3457 passed`).

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
