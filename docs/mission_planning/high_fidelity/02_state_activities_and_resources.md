# State Machines, Activity Templates, and Resource Propagation

## Mode and State Machines

Subsystems should expose allowed state transitions, not only numeric margins.

Example:

```text
safe -> standby -> payload_ready -> imaging -> downlink -> standby
```

Each transition can carry:

- required preconditions
- required command authority
- setup duration
- cooldown duration
- resource effects
- exclusivity constraints
- failure/degraded-mode behavior
- telemetry confirmation requirements

The planner should use state machines to avoid impossible activity sequences.

## Activity Templates

Mission activities should be built from reusable templates.

Candidate templates:

- observe target
- downlink recorder
- uplink command load
- tracking pass
- health check
- slew
- payload warm-up
- payload cooldown
- calibration
- impulsive maneuver
- finite burn
- safe-mode recovery
- recorder management
- payload inhibit / enable

Each template should declare:

- required subsystem states
- produced subsystem states
- resource effects
- time effects
- setup/teardown activities
- dependencies
- exclusivity
- authority requirements
- source-window requirements
- validation level
- provenance

Current baseline `activity_template.v1` artifacts expose advisory
`operational_hints` for setup duration, cooldown duration, and telemetry
confirmation requirements plus `subsystem_state_hints` for required and
produced subsystem-state declarations. Instantiation preserves those hints in
normalized timeline-row provenance without reserving resources, simulating
state transitions, mutating schedules, granting command authority, or executing
commands.

## Resource Propagation

A mature planner should roll resources through time.

Resource propagation should include:

- battery state of charge
- storage used
- fuel remaining
- thermal state
- data latency
- downlink completion
- payload duty cycle
- antenna occupancy
- station reservation occupancy

The first implementation can be deterministic and piecewise constant. The key
requirement is that the planner emits an auditable projection:

- starting state
- activity effects
- environmental effects
- ending state
- minimum margin
- violations
- assumptions

## Environment and Dynamics Fidelity

High-fidelity mission planning still needs better astrodynamics and event
models.

Feature areas:

- drag and atmosphere interfaces
- solar radiation pressure
- higher-order gravity
- third-body perturbations
- Earth orientation
- time-system conversions
- frame transformations
- refined AOS/LOS event timing
- refined eclipse boundaries
- lighting conditions
- conjunction and keep-out screening
- finite-burn dynamics
- maneuver execution covariance

Each model should declare its validation level and known limits.
