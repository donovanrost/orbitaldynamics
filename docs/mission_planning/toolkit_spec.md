# Mission Planning Toolkit Spec

## Project Thesis

OrbitalDynamics is an Elixir mission planning toolkit that uses the BEAM for
orchestration, distribution, supervision, reproducibility, and workflow
composition while keeping numerical kernels behind explicit, swappable
contracts.

The project should not depend on pure Elixir winning dense floating-point
performance. Instead, it should test whether a mission planning system can keep
scenario definition, study execution, distributed search, audit trails, and
operator-facing workflows in Elixir while allowing numerical work to run through
scalar Elixir, Nx/EXLA, or native high-fidelity backends.

The core claim is:

> The BEAM can provide a strong mission planning runtime when numerical model
> boundaries are explicit, deterministic, observable, and replaceable.

## Capability Levels

### Level 0: Transparent Propagation Baseline

The toolkit can propagate one scenario with clearly stated assumptions.

Required capabilities:

- Cartesian state vectors with explicit units, epoch, and frame.
- Central-body metadata with gravitational parameter units.
- A deterministic scalar two-body propagator.
- Trajectory output that records force model, numerical method, units, frame,
  epoch scale, and central-body constants.
- Tests against analytical or conserved-quantity references.

Current status: mostly implemented.

### Level 1: Reproducible Batch Studies

The toolkit can run many scenarios as a reproducible study.

Required capabilities:

- A serializable study manifest.
- Stable scenario identifiers.
- Deterministic result ordering.
- Configurable local concurrency.
- Error isolation per scenario.
- Study run metadata: software version, backend, node, options, seed manifest,
  wall-clock timing, and assumptions.

Current status: partially implemented through `ScenarioRunner`, `Study`, and
`StudyRun`, without persistence for run metadata.

### Level 2: Useful LEO Mission Analysis

The toolkit can answer practical low-Earth-orbit planning questions.

Required capabilities:

- Two-body and J2 propagation.
- Ground station definitions.
- Line-of-sight access windows.
- Eclipse interval detection.
- Simple impulsive maneuvers.
- Monte Carlo perturbation of initial states and spacecraft parameters.
- Reproducible reports that summarize contacts, eclipses, maneuver costs, and
  constraint violations.

This is the first target for "actually useful" mission planning.

### Level 3: Pluggable High-Fidelity Analysis

The toolkit can delegate high-fidelity numerical work without changing the
planning layer.

Required capabilities:

- Behaviour-based propagator contracts.
- Pluggable frame, time, and ephemeris providers.
- Validation against trusted external tools or reference cases.
- Explicit model capability declarations.
- Clear separation between educational, analysis-grade, and validated models.

Candidate integrations include SPICE, Orekit, GMAT, Tudat, native Rust/C/NIFs,
Nx/EXLA kernels, or external service adapters.

### Level 4: Operational Planning Products

The toolkit can produce mission planning artifacts.

Required capabilities:

- Timeline products.
- Contact schedules.
- Maneuver tables.
- Constraint summaries.
- Reproducible study archives.
- Operator-facing APIs or UI surfaces.
- Audit trails for inputs, assumptions, backend choices, and generated outputs.

This level is not flight certification. It is operationally shaped mission
planning with traceable assumptions.

## Domain Model

The project should keep the following nouns explicit. New modules should fit one
of these concepts or justify a new concept in the spec.

### Existing Concepts

- `CentralBody`: gravitational body metadata, including standard gravitational
  parameter.
- `Epoch`: simulation time as seconds since J2000 in a declared scale.
- `Frame`: reference frame metadata and compatibility helpers.
- `Scenario`: one mission analysis case.
- `ScenarioRunner`: concurrent evaluator for scenario batches.
- `Spacecraft`: spacecraft physical metadata.
- `StateVector`: Cartesian position and velocity with epoch and frame.
- `Trajectory`: propagation output and model assumptions.
- `OrbitElements`: two-body osculating classical element conversion from a
  Cartesian state without frame or time-system transformation.
- `Units`: executable suffix-based unit policy for public structs, manifests,
  and artifacts.

Numerical helper modules should expose capability metadata when they introduce a
new computed product. For example, `OrbitalDynamics.OrbitElements.capabilities/0`
labels its two-body assumption, validation level, units, frame policy, and
singular-angle behavior. Event detector modules likewise declare their sampled
models, timing policy, and known limits. Search, scoring, and planning-summary
helpers should label whether they are deterministic artifact contracts,
assumption declarations, or validated numerical models.

### Planned Concepts

- `Propagator`: backend that advances a scenario into a trajectory.
- `ForceModel`: acceleration or dynamics contribution with declared
  assumptions.
- `Environment`: central bodies, atmosphere, ephemerides, solar data, and other
  external state used by models.
- `EventDetector`: detector for contacts, eclipses, apsides, crossings, and
  other trajectory events.
- `Constraint`: deterministic evaluator that turns mission outputs into pass,
  fail, or scored results.
- `Maneuver`: impulsive or finite-burn action with epoch, frame, and units.
- `Search`: deterministic expansion of a base scenario into candidate scenarios
  with an explicit objective and ranking policy.
- `Study`: reproducible collection of scenarios, model choices, seeds, and
  requested outputs.
- `StudyRun`: execution record for a study, including backend, node, timing,
  software version, and failures.
- `ResultSet`: structured collection of trajectories, events, constraints, and
  summary products.

## Behaviour Contracts

All behaviour contracts should prefer explicit `{:ok, value} | {:error, reason}`
returns for public safe APIs. Bang functions may raise when useful for test setup
or interactive use.

### Propagator

```elixir
defmodule OrbitalDynamics.Propagator do
  @callback propagate(OrbitalDynamics.Scenario.t(), keyword()) ::
              {:ok, OrbitalDynamics.Trajectory.t()} | {:error, term()}

  @callback capabilities() :: map()
end
```

Expected properties:

- Deterministic for identical inputs and options.
- Does not mutate global state.
- Records numerical assumptions in the output.
- Returns domain errors through `{:error, reason}` from the safe API.
- May have backend-specific constraints such as fixed tensor shape or supported
  force models.

### Batch Propagator

```elixir
defmodule OrbitalDynamics.BatchPropagator do
  @callback propagate_many([OrbitalDynamics.Scenario.t()], keyword()) ::
              {:ok, [OrbitalDynamics.Trajectory.t()]} | {:error, term()}
end
```

Expected properties:

- Preserves input ordering.
- Reports per-scenario failures when possible.
- Declares batching restrictions.
- Can be compared against scalar `Propagator` output.

### Event Detector

```elixir
defmodule OrbitalDynamics.EventDetector do
  @callback detect(OrbitalDynamics.Trajectory.t(), keyword()) ::
              {:ok, [event()]} | {:error, term()}

  @type event :: %{
          required(:type) => atom(),
          required(:starts_at) => OrbitalDynamics.Epoch.t(),
          optional(:ends_at) => OrbitalDynamics.Epoch.t(),
          optional(:metadata) => map()
        }
end
```

Expected properties:

- Pure evaluation over trajectory and declared environment inputs.
- Explicit event precision and interpolation assumptions.
- No hidden frame or time conversions.

### Constraint

```elixir
defmodule OrbitalDynamics.Constraint do
  @callback evaluate(term(), keyword()) ::
              {:ok, result()} | {:error, term()}

  @type result :: %{
          required(:status) => :pass | :fail | :warning,
          optional(:score) => number(),
          optional(:metadata) => map()
        }
end
```

Expected properties:

- Deterministic.
- Serializable.
- Suitable for local or remote execution.

## Numerical Accuracy Policy

Every numerical feature must state its validation level.

### Validation Levels

- `:educational`: useful for learning, demos, or rough intuition. Not suitable
  for planning decisions.
- `:analysis`: suitable for early trade studies within stated tolerances.
- `:artifact_contract`: suitable for artifact schema and public-field
  regression checks, not as physics truth.
- `:assumption_declared`: suitable for explicitly documented assumptions or
  model capabilities that do not yet have reference validation.
- `:validated`: compared against trusted references across documented cases.

`OrbitalDynamics.Validation.tolerance_policy/0` is the executable summary of
the current comparison model. Numeric scalar checks use absolute field
tolerances, numeric vector checks use maximum component-wise absolute error, and
current sampled event detectors only claim timing bounded by maximum adjacent
trajectory sample spacing.

`OrbitalDynamics.units_policy/0` is the executable summary of the current unit
model. Distance fields use kilometers, velocity fields use kilometers per
second, epochs and durations use seconds, angles use degrees, and the package
does not perform hidden frame or time-scale conversions.

### Required Validation Evidence

New propagators or event detectors should include at least one of:

- Analytical reference case.
- Conserved quantity check, such as specific energy or angular momentum.
- Comparison against an established tool such as GMAT, Orekit, STK, Tudat, or
  poliastro.
- Published benchmark or known reference trajectory.

### Required Tolerance Metadata

Each validated model should document:

- Position tolerance.
- Velocity tolerance.
- Event-time tolerance.
- Propagation duration covered by the validation.
- Orbit regime covered by the validation.
- Step size or adaptive error settings.
- Known failure modes.

No model should imply more precision than its tests support.

## Backend Evaluation Plan

The project should evaluate backends before committing to them as defaults.

### Backends to Compare

- Scalar Elixir.
- Scalar Elixir with `Task.async_stream`.
- Nx default evaluator.
- EXLA CPU.
- EXLA GPU, when available.
- Native backend candidates, when introduced.

### Initial Nx Experiment

Implement batched fixed-step RK4 two-body propagation for homogeneous scenario
groups.

Input shape:

- Position tensor: `{batch, 3}` in kilometers.
- Velocity tensor: `{batch, 3}` in kilometers per second.
- Duration tensor or scalar in seconds.
- Step size scalar in seconds.
- Central-body `mu` scalar in km^3/s^2.

Output shape:

- Position tensor: `{batch, samples, 3}` or `{samples, batch, 3}`.
- Velocity tensor: matching position shape.
- Epoch offsets for each sample.
- Assumption metadata outside the compiled numerical kernel.

The scalar two-body propagator remains the correctness oracle.

### Metrics

For each backend, measure:

- First-call compile time.
- Steady-state throughput.
- Memory use.
- Batch size sensitivity.
- Numerical agreement with scalar baseline.
- Result serialization cost.
- Remote-node transfer overhead.
- Failure and retry behavior.
- Developer complexity.

### Decision Outcomes

Each backend should end in one of these states:

- `:default`: good enough to use by default for a class of workloads.
- `:optional_accelerator`: useful when installed and when workload shape fits.
- `:specialized`: useful for a narrow model or hardware target.
- `:rejected`: not worth carrying for now.

## First Useful Mission Slice

The first end-to-end planning target is a LEO access-window study.

### Scenario

Given:

- One or more LEO spacecraft initial states.
- One Earth central body.
- One or more ground stations.
- A study duration.
- A propagation backend.
- A set of model assumptions.

Produce:

- Trajectories.
- Ground-station access windows.
- Eclipse intervals.
- Optional Monte Carlo dispersions.
- A reproducible study run report.

### Minimum Features

- Scalar two-body propagation.
- J2 propagation.
- Ground station geodetic coordinates.
- Earth rotation or an explicit simplified Earth-fixed/inertial assumption.
- Line-of-sight geometry.
- Eclipse geometry using a documented cylindrical or conical shadow model.
- Study manifest.
- Deterministic result ordering.
- Per-scenario errors.

### Acceptance Criteria

- Runs at least 10,000 LEO scenarios locally with deterministic result ordering.
- Reproduces the same study from a manifest.
- Compares scalar and Nx results within stated tolerances.
- Produces access windows for at least one ground station.
- Produces eclipse intervals for at least one orbit.
- Runs the same study across multiple BEAM nodes and reports scheduling and
  transfer overhead.
- Emits assumptions with every generated result.

## Distribution Thesis

The BEAM distribution work should be evaluated on mission planning properties,
not only raw speed.

Questions to answer:

- What scenario size makes distribution worthwhile?
- How much result payload can be moved before transfer dominates computation?
- How are node failures represented in study results?
- Can a study be resumed without corrupting reproducibility?
- Can random seeds be partitioned predictably across nodes?
- Does supervision make long-running studies easier to operate than equivalent
  Python multiprocessing or job-queue approaches?

Distribution is a success if it improves throughput, robustness, or operational
clarity for meaningful study workloads. It is not a success merely because tasks
can run on multiple nodes.

## Non-Goals

- Flight certification.
- Replacing GMAT, Orekit, STK, Tudat, or SPICE in the near term.
- Hidden time-scale or frame conversion magic.
- A single generic "engine" abstraction before repeated patterns justify it.
- Precision claims without validation evidence.
- Optimizing pure Elixir floating-point loops before defining the workload.

## Near-Term Implementation Plan

1. Add `OrbitalDynamics.Propagator` behaviour and make the scalar two-body
   module implement it.
2. Harden `TwoBody.propagate/2` so expected domain failures return
   `{:error, reason}`.
3. Add central-body constructors and validation.
4. Replace float-equality-based sample generation with indexed sample
   generation.
5. Add conserved-quantity and edge-case tests for scalar two-body propagation.
6. Add a `Study` and `StudyRun` data model.
7. Add a benchmark harness for scalar local, scalar concurrent, and future Nx
   backends.
8. Implement the Nx batched two-body experiment behind a separate backend.
9. Decide whether Nx is a default backend, optional accelerator, specialized
   backend, or rejected experiment.
10. Start the LEO access-window slice with J2 and ground-station geometry.

Items 1 through 6 have an initial implementation.

## Open Questions

- Should the public API expose structs only, maps only, or both for study
  manifests?
- What file format should study manifests use: Elixir terms, JSON, YAML, or
  another format?
- Should Nx and EXLA be optional dependencies, separate Mix targets, or a
  companion package?
- Which external reference tool should be the first validation target?
- What is the minimum useful distributed study size?
- How much frame and time-system support is required before ground-station
  access windows are meaningful?
