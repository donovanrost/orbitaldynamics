# 3. Propagation and Force Models

- `implemented`: scalar two-body and J2 fixed-step RK4 propagators; scalar
  two-body also supports explicit educational adaptive step-doubling RK4 with
  declared position/velocity tolerances and manifest-backed propagator options;
  impulsive burns via segmented propagation; Nx and EXLA two-body/J2 experiments;
  propagator capability declarations; `BatchPropagator` support for batchable
  kernels; `Validation.backend_acceptance_policy/0` declares reference-default,
  experimental-accelerator, and future external-service acceptance tiers plus
  benchmark evidence requirements; the public `study_benchmark_summary/2`
  facade interprets persisted comparison artifacts with those acceptance tiers
  without rerunning studies; maneuver review reports preserve declared
  execution uncertainty as review metadata and expose missing-vs-declared counts
  plus report-level max timing, max delta-v, and total declared delta-v
  3-sigma review envelopes;
  `Environment.ExponentialAtmosphereProvider` exposes a validated
  single-scale-height atmosphere-density provider contract;
  `ForceModels.AtmosphericDrag` and the public
  `atmospheric_drag_acceleration/4` facade combine it with spacecraft ballistic
  inputs and constant Earth co-rotation in a deterministic standalone
  acceleration evaluator without connecting drag to current propagators; the
  evaluator has a validation-registry record plus a curated, tolerance-backed
  400 km reference fixture exercised through the public facade.
- `partial`: maneuver support is impulsive only; J2 is the only perturbation;
  adaptive integration is currently limited to scalar two-body step-doubling and
  is not event/root solved; backend comparisons now have acceptance tiers but
  still lack external reference-tool acceptance evidence; maneuver uncertainty
  envelopes are review metadata, not propagated state dispersion; atmosphere
  density is consumed by a standalone acceleration model but not by propagators.
- `near-term`: adaptive/root-solved event workflows beyond scalar two-body
  step-doubling, richer maneuver uncertainty propagation beyond review metadata,
  and cleaner backend contracts for shape and capability limits.
- `later`: higher-order gravity, drag propagation that consumes atmosphere
  providers, solar radiation pressure, third-body perturbations, finite burns, native/NIF
  kernels, and external high-fidelity backend adapters.
- `out of scope`: hiding model fidelity behind an opaque universal propagator.
  The planning layer should know and record which force model it used.
