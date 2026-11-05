# Reaction-wheel momentum and unloading

The optional `reaction_wheels` resource model screens prescribed attitude paths
against rotor momentum and motor torque limits. It carries signed wheel state
through acquisition, tracking, settling, idle time, terminal return, execution
replay and replanning. It supports arbitrary configured missions; the checked-in
example uses invented hardware, not Reflect Orbital specifications.

## Run the examples

```sh
MIX_ENV=test mix orbital_dynamics.mission.wheels --output-dir tmp/wheel_cases
MIX_ENV=test mix orbital_dynamics.mission.operations \
  --scenario studies/wheel_momentum_operations.json --output-dir tmp/wheel_ops
```

Use fresh output directories. The first command writes three complete reports,
a compact comparison and a README. An intentionally violated case passes the
quality check when the planner correctly rejects it. The second executes a
maintenance activity and service in two simulated cycles. Compact observations
are in [reaction_wheel_observation.json](reaction_wheel_observation.json).

| Case | Expected behavior |
| --- | --- |
| Feasible 60° principal-axis slew and return | Wheel demand peaks at ±1.745329252 Nms; final momentum is zero without external torque |
| Stationary body, 0.02 Nm disturbance, 100 s | Required wheel momentum reaches 2 Nms, exceeding the 1 Nms limit; no usable plan |
| Same disturbance, external unloading torque −0.055 Nm for 20 s | Final momentum is 0.9 Nms; unloading and service both fit |

The unload reserves 20–40 s, consumes one maintenance token and draws 12 W. The
service reserves 70–80 s, consumes one service token and draws 2 W. With an initial
10 Wh battery, final energy is 9.927777778 Wh. Execution boundaries at 60 s and
90 s carry wheel momentum of 0.1 and 0.7 Nms respectively; the final horizon
forecast remains 0.9 Nms. Completing maintenance never resets wheel momentum.

## Configuration and units

See [wheel_momentum_planning.json](../../studies/wheel_momentum_planning.json).
Each asset may have one wheel model with exactly three orthonormal body axes,
signed initial rotor momenta, positive per-wheel momentum and motor torque
capacities, constant body disturbance torque, and named external unload torques.
Vectors use wheel order except explicitly named `*_body_nm` vectors. Units are
kg m², N m and N m s. Internal dynamics use radians; attitude interfaces use degrees.

`frame` must be `body_principal_axes`. Principal moments must match the asset's
[rigid-body configuration](rigid_body_torque.md). Axes may be signed or permuted;
small orthonormality roundoff is normalized and reported. Redundant wheel arrays
are unsupported. The separate rigid-body net torque box remains an additional
constraint; it is not a substitute for wheel motor limits.

An unload request has type `momentum_unload`. Its selected mode must declare
`parameters.momentum_unloading: true` and match a configured `unload_modes` entry.
External torque must fit `max_unload_torque_body_nm`. Body rate and acceleration
must remain below 1e-8 degrees/s and degrees/s² at sampled checks. An ordinary
mode cannot silently apply unloading torque. The generic `fixed_attitude` model
provides explicitly declared inertial pointing tasks without optical claims.

The original example uses an explicit protected maintenance reservation. The
optional [automatic maintenance search](automatic_maintenance.md) can instead
choose placement and duration/mode alternatives from declared requests. It checks
maintenance together with services, avoiding rejection of a necessary prefix.
It does not synthesize unloading direction, actuator availability or engineering
parameters from scratch.
Static budgets and battery mode loads account for declared costs; wheel torque
is not automatically converted into electrical power or propellant consumption.

## Dynamics and checks

Let R map body vectors to inertial vectors, A contain the wheel axes, I be body
principal inertia, ω be body angular velocity and h the signed rotor momenta.
The model evolves total inertial angular momentum:

```
L_start = R_start (I ω_start + A h_start)
L_end   = L_start + R_mid (τ_disturbance + τ_unload) Δt
h_end   = Aᵀ (R_endᵀ L_end − I ω_end)
hdot    = Aᵀ (τ_external − I α − ω × (I ω + A h))
```

The last expression is signed wheel motor torque. It includes rotor gyroscopic
coupling. Rotor momentum is distinct from the body's Iω. With zero external
torque the update conserves total inertial momentum; nonzero body torque uses
midpoint quadrature. Unloading applies a declared external torque and may carry
momentum through zero. There is no clipping, reset or fictitious internal dump.

At each resource interval the model checks start, midpoint and end momentum and
motor torque with absolute comparison tolerance 1e-12 Nms/Nm. Resource cadence
comparisons remain visible in reports. Generated phase endpoints use one-sided
kinematics to avoid mixing acceleration phases. Checks are sampled, and external
torque integration during rotation has quadrature error; they do not certify
continuous feasibility. Missing kinematics produces unknown evidence.

A violated report retains counterfactual demand beyond capacity for diagnosis.
It cannot become an accepted plan snapshot. A finite declared execution state
outside an operating limit is retained independently of future planning success;
see [execution checkpoints](execution_checkpoints.md). State packets for
configured wheel resources require `wheel_momentum_nms`, mapping each model ID
to a signed three-element vector. Advance binds these values to the child
configuration's `initial_momentum_nms`; later revisions preserve them. Battery-only
missions retain their existing packet format and behavior.

## Evidence boundary

Known-answer tests cover constant disturbance, a costed external unload,
principal-axis slews, inertial conservation, gyroscopic motor demand, signed axes,
capacity rejection and state continuity through replay and revisions. They test
the declared equations and orchestration. The independent offline validator
now independently checks saved moving histories, motor demand, sampled limits,
phase bindings and execution handoff on declared kinematics with signed coordinate
wheel axes. Missing kinematic evidence or unsupported configurations remain
**partial**. See [moving resource validation](moving_resource_validation.md) for
its conditional scope and independent numerical evidence.

This model omits wheel rpm conversion, redundant allocation, magnetic field and
magnetorquer constraints, thruster geometry, propellant depletion, time-varying
aerodynamic/solar-pressure torques, friction, flexible dynamics, thermal derating
and closed-loop control error. External unloading availability is an assumption
in each named mode, not a demonstrated actuator capability.

Physical context: [NASA's small-spacecraft GNC survey](https://www.nasa.gov/smallsat-institute/sst-soa/guidance-navigation-and-control/)
describes reaction wheels and external momentum management;
[MIT's angular momentum and Euler-equation notes](https://ocw.mit.edu/courses/16-07-dynamics-fall-2009/5e1d8699338146e5127080b880b906d6_MIT16_07F09_Lec28.pdf)
provide the rigid-body dynamics background. These references do not validate this
implementation or the invented spacecraft parameters.

Focused development check:

```sh
mix test.fast test/orbital_dynamics/mission_analysis/resource/reaction_wheels_test.exs \
  test/orbital_dynamics/mission_analysis/resource/reaction_wheel_reference_test.exs \
  test/mix/tasks/orbital_dynamics.mission.wheels_test.exs
```

Independent numerical verification is now available with
`MIX_ENV=test mix orbital_dynamics.mission.verify_wheels --output-dir tmp/wheel_verification`.
See the [frozen reference bundle](../../priv/validation/reaction_wheels/README.md)
and [recorded comparison](wheel_verification_observation.json). This verifies
finite declared dynamics cases, separately from saved-plan accounting checks.
