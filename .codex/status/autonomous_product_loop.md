# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Make two-body plus atmospheric-drag studies reproducible from JSON manifests.

Status:
Implemented and verified; publish pending.

Why this slice:
The propagated model is public and validated, but callers cannot yet select it
from checked-in study manifests or serialize its built-in atmosphere parameters.
Manifest support is the next product boundary between a programmatic experiment
and a reproducible workflow.

Files changed:
- Manifest parser, typed atmosphere-provider input, schema document, and
  circular-LEO scenario fixture.
- TwoBodyDrag capability metadata, runnable demo manifest, README/capability
  docs, focused tests, generated schema/reference/catalog artifacts, and
  manifest validation fixtures.

Behavior changed:
Manifest key `two_body_drag` accepts the typed network-free
`exponential_reference` provider configuration. Generated circular-LEO
spacecraft preserve propellant, area, and drag coefficient. Other propagators
reject the atmosphere option; adaptive drag options and custom provider names
are rejected instead of ignored.

Public proof:
JSON round-trip tests parse module/keyword configuration, run the public study
path, and validate a result artifact that preserves provider parameters and
drag assumptions. `studies/two_body_drag_demo.json` also linted and ran through
the CLI with one trajectory, zero errors, and a schema-valid result.

Docs read/changed:
- Read `docs/feature_set/capability_map/03_propagation_and_force_models.md`.
- Read `docs/feature_set/definition_of_feature_complete.md`.
- Read the manifest parser/schema, circular-LEO fixture generator, typed
  Earth-rotation provider-spec precedent, and manifest validation tests.
- Updated README, capability map/snapshot/completeness docs, and canonical
  examples for the manifest-backed boundary.

Verification:
Focused manifest, propagator, scenario-fixture, validation-fixture, capability,
and golden-artifact suites pass. Manifest/result/schema CLI proof passes. Full
`mix test --timeout 180000`: 3,469 passed.

Artifact regeneration:
Regenerated manifest schema, field reference, manifest lint report, and public
capability catalog plus the affected validation-reference aggregate. Reference
expectations now record 7 manifest propagators and the live 4,121-row field
catalog.

Level 6 pillar advanced:
Reproducibility, provenance, and durable manifest-backed numerical workflows.

Parent review:
Complete. Provider choice is allowlisted and network-free, unsupported options
fail closed, non-drag defaults are unchanged, generated ballistic fields retain
old defaults, and no custom module loading was added. Sidecar delegation remains
unavailable under the active runtime policy.

Previous published slice:
- `90622f55` Add opt-in atmospheric drag propagation (`3465 passed`).

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
