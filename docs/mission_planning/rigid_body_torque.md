# Rigid-body inertia and torque capacity

The attitude planner can check the ideal body torque needed for its constructed
motion and sampled tracking profile. This adds an actuator-capacity constraint to
the existing rate and acceleration limits. It is opt-in per spacecraft; omitted
configuration retains the previous kinematic behavior and report shape.

## Configure

Add `rigid_body` to an asset's attitude configuration:

```json
{
  "frame": "body_principal_axes",
  "principal_moments_kg_m2": [100, 120, 160],
  "max_body_torque_nm": [1, 1, 1]
}
```

The core Elixir policy accepts the same fields as atom keys, with
`frame: :body_principal_axes`. These are synthetic example values, not estimates
of a Reflect Orbital spacecraft.

Moments are positive principal moments about the center of mass, in kg m². They
must satisfy the rigid-body triangle inequalities. Equality is permitted for an
ideal planar mass distribution. Spacecraft body X/Y/Z must coincide with those
principal axes; arbitrary products of inertia or a separate inertia-frame rotation
are not supported in this slice. Inertia is fixed through the planning horizon.

Capacities are positive Nm values defining a symmetric **simultaneously available
body torque box**: each component must fit its declared bound. These are net body
torque capacities, not individual reaction-wheel ratings. Deriving that box from
a particular actuator layout is outside the model. No inertia is inferred from
dry mass, mirror area or optical parameters.

## Calculation and coverage

The model uses Euler's rigid-body equation in body principal axes:

```
tau_body = I * alpha_body + omega_body × (I * omega_body)
```

Here `I` is the diagonal inertia matrix. Quaternion profiles use active
body-to-inertial rotations, and their angular velocity and acceleration components
are inertial degrees/s and degrees/s². The check converts both vectors to body
axes and radians before calculating Nm. The acceleration transform is valid
because the rotating-frame correction for the angular-velocity vector itself is
`omega × omega = 0`.

The cross product matters: steady rotation about a non-principal axis can require
torque even when angular acceleration is zero. See the equations and inertial
angular-momentum derivation in [MIT 16.07 Lecture 28, pages 1–3](https://ocw.mit.edu/courses/16-07-dynamics-fall-2009/5e1d8699338146e5127080b880b906d6_MIT16_07F09_Lec28.pdf).

Tracking checks use the existing sampled finite-difference rate/acceleration
estimates. Each profile point retains its signed required torque, capacity and
component margins. A tracking torque violation rejects that placement. Sampling
and derivative-resolution limits still apply; this is no continuous tracking
certificate.

Constructed acquisition, braking, slew, cruise, settling and tracking-ramp phases
have constant inertial acceleration parallel to angular velocity. Their rotation
axis therefore has constant body components. Within each such phase, each torque
component is a constant acceleration term plus a coefficient times speed squared.
Speed is monotonic or constant, so the maximum absolute component occurs at a
phase endpoint. Both sides of acceleration switches are checked explicitly.

This gives a phase endpoint envelope for the **generated fixed-axis phases**,
including cruise's gyroscopic demand. It is not an envelope for arbitrary
non-collinear motion. The evaluator rejects phases that violate that assumption
rather than applying the envelope silently. Acceleration switches still assume
unlimited jerk.

The check is applied through the shared motion constructor, so it covers initial
acquisition, inter-service transitions, outgoing reservations, and terminal
braking/return for idle spacecraft. Exact protected activities are checked too.
A protected torque failure is exposed as a commitment conflict with structured
torque evidence. Other physical checks remain in force.

## Run the examples

```sh
MIX_ENV=test mix orbital_dynamics.mission.revision baseline \
  --study studies/rigid_body_planning.json --output-dir tmp/rigid_body_reference

MIX_ENV=test mix orbital_dynamics.mission.revision baseline \
  --study studies/rigid_body_limited_planning.json --output-dir tmp/rigid_body_limited

MIX_ENV=test mix orbital_dynamics.mission.explain \
  --snapshot tmp/rigid_body_limited/baseline_snapshot.json \
  --request early-3 --output-dir tmp/rigid_body_explanation
```

Use fresh output filenames. Both configurations use the existing one-spacecraft,
two-service reference mission. With the synthetic 1 Nm body box both services
remain scheduled. Reducing the box to 0.01 Nm leaves both requests unfulfilled;
the vehicle's idle horizon remains supported. Conservative opportunities are
unchanged. The request explanation identifies incoming transition failures and
negative body torque margins in Nm. Some tested starts can fail timing before
the torque check is reached.

The current constructor uses the configured acceleration rather than optimizing
motion for torque. Rejecting that path does not prove no slower path can fit.
A unit example explicitly lowers the declared acceleration and demonstrates a
feasible lower-torque motion within the same time gap.

## Evidence and limits

Tests include hand-computed principal-axis and gyroscopic cases, body/inertial
frame conversion, an independent finite difference of inertial angular momentum,
phase envelopes checked against dense actual motion samples, tracking rejection,
protected replay and idle terminal braking. The existing complete reference
report is unchanged when the option is omitted. Recorded results are in
[rigid_body_torque_observation.json](rigid_body_torque_observation.json).

This remains an ideal rigid-body screening model. External disturbance torque,
solar-pressure torque, wheel allocation, stored wheel momentum, wheel-speed
limits, momentum unloading, flexible-body settling, actuator power/temperature
derating and closed-loop control error are not included. In particular, body
angular momentum is not treated as reaction-wheel stored momentum. Those need
additional state and actuator models. Declared battery phase loads are retained;
torque demand is not converted automatically into electrical power consumption.

The [independent plan checker](independent_plan_validation.md) continues to check
structure and supported resource arithmetic. It does not independently validate
this torque or other attitude-feasibility evidence. These tests establish behavior
within declared equations and assumptions, not flight validation.

Focused development check:

```sh
mix test.fast test/orbital_dynamics/mission_analysis/attitude/rigid_body_test.exs \
  test/orbital_dynamics/mission_analysis/attitude/rigid_body_reference_test.exs
```

The optional [reaction-wheel resource model](reaction_wheels.md) now adds rotor
momentum, motor allocation for three orthogonal wheels, constant disturbances
and declared external unloading. The exclusions above describe the standalone
rigid-body torque box; the wheel model has its own documented limits.
