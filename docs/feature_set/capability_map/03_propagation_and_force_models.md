# 3. Propagation and Force Models

- `implemented`: scalar two-body and J2 fixed-step RK4 propagators; scalar
  two-body also supports explicit educational adaptive step-doubling RK4 with
  declared position/velocity tolerances and manifest-backed propagator options;
  impulsive burns via segmented propagation; Nx and EXLA two-body/J2 experiments;
  propagator capability declarations; `BatchPropagator` support for batchable
  kernels; `Validation.backend_acceptance_policy/0` declares reference-default,
  experimental-accelerator, and future external-service acceptance tiers plus
  benchmark evidence requirements; maneuver review reports preserve declared
  execution uncertainty as review metadata and expose missing-vs-declared counts
  plus report-level max timing, max delta-v, and total declared delta-v
  3-sigma review envelopes;
  `Environment.ExponentialAtmosphereProvider` exposes a validated
  single-scale-height atmosphere-density provider contract for drag-interface
  experiments without connecting it to current propagators.
- `partial`: maneuver support is impulsive only; J2 is the only perturbation;
  adaptive integration is currently limited to scalar two-body step-doubling and
  is not event/root solved; backend comparisons now have acceptance tiers but
  still lack external reference-tool acceptance evidence; maneuver uncertainty
  envelopes are review metadata, not propagated state dispersion; atmosphere
  density is interface-only and is not consumed by force models.
- `near-term`: adaptive/root-solved event workflows beyond scalar two-body
  step-doubling, richer maneuver uncertainty propagation beyond review metadata,
  and cleaner backend contracts for shape and capability limits.
- `later`: higher-order gravity, drag propagation that consumes atmosphere
  providers, solar radiation pressure, third-body perturbations, finite burns, native/NIF
  kernels, and external high-fidelity backend adapters.
- `out of scope`: hiding model fidelity behind an opaque universal propagator.
  The planning layer should know and record which force model it used.

