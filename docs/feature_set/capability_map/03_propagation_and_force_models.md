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
  inputs and constant Earth co-rotation in a deterministic acceleration
  evaluator; the opt-in scalar `Propagators.TwoBodyDrag` evaluates it at every
  fixed-step RK4 stage without changing existing propagator defaults. Both the
  evaluator and propagator have validation-registry records plus curated,
  tolerance-backed 400 km reference fixtures. `TwoBodyDrag` is available through
  direct/programmatic `Study` APIs and JSON manifests using the built-in,
  network-free `exponential_reference` atmosphere provider. Manifest-backed
  circular-LEO scenarios carry dry/propellant mass, area, and drag coefficient;
  custom atmosphere-provider modules remain programmatic-only;
  the opt-in scalar `Propagators.J2Drag` and public `propagate_j2_drag/2` facade
  sum point-mass, J2, and provider-backed drag acceleration in one RK4
  derivative rather than chaining propagators. The path is programmatic-only,
  captures one offline atmosphere/rotation policy with source revision and
  full-horizon coverage before integration, accepts Earth/J2000/TDB LEO cases
  for at most 24 hours, defaults to a 10 s maximum step with a 30 s hard limit,
  and records fixed ballistic and force-component assumptions. Its published
  Earth-specific numeric envelope bounds `mu` to 350,000--450,000 km^3/s^2,
  radius to 6,000--7,000 km, J2 to 0--0.002, total spacecraft mass to
  0.1--10,000,000 kg, drag area to 0--1,000,000 m^2, drag coefficient to 0--5,
  and density to 0--0.001 kg/m^3 before force arithmetic. Out-of-envelope
  values return typed errors. A 24-hour 10 s versus 5 s fixture supplies
  internal step-convergence evidence only.
- `partial`: maneuver support is impulsive only; J2 and atmospheric drag are
  combined only in the bounded scalar `J2Drag` path, not in existing scalar
  defaults or accelerated backends;
  adaptive integration is currently limited to scalar two-body step-doubling and
  is not event/root solved; backend comparisons now have acceptance tiers but
  still lack external reference-tool acceptance evidence; maneuver uncertainty
  envelopes are review metadata, not propagated state dispersion; drag uses a
  reference atmosphere without space-weather calibration or winds.
- `near-term`: adaptive/root-solved event workflows beyond scalar two-body
  step-doubling, richer maneuver uncertainty propagation beyond review metadata,
  and cleaner backend contracts for shape and capability limits.
- `later`: higher-order gravity, higher-fidelity combined propagation, solar radiation
  pressure, third-body perturbations, finite burns, native/NIF
  kernels, and external high-fidelity backend adapters.
- `out of scope`: hiding model fidelity behind an opaque universal propagator.
  The planning layer should know and record which force model it used.
