# Independent resource validation through maneuvers

The offline checker now checks moving reaction-wheel histories and changing
battery loads on saved reference plans and execution prefixes. This closes the
two resource-accounting gaps previously reported on the motion-checkpoint and
illumination examples. A pass means consistency with the declared sampled motion
and resource model. It does not establish the truth of spacecraft state, the
correctness of pointing/orbit geometry, or continuous-time feasibility.

## Wheel accounting and evidence

Each wheel resource sample now records the exact start, midpoint and end
quaternion, inertial angular rate and acceleration supplied to the resource model.
The independent checker uses its own direction-cosine matrix and vector arithmetic;
it calls no producer quaternion, wheel, motion, pointing or replay functions.

Starting from declared initial total angular momentum, it accumulates external
angular impulse globally in inertial axes. At each interval endpoint and midpoint
it subtracts body angular momentum and projects the remainder onto the configured
wheel axes. Motor demand follows body-frame Euler balance, including rotor
momentum in the gyroscopic term. The external impulse uses midpoint quadrature,
matching the declared discrete integration contract. This checks that contract;
it is not a higher-accuracy reconstruction of continuous torque integration.

Every configured cadence is checked separately. Initial/final states, every saved
state, midpoint momentum/motor/total-momentum metrics, signed endpoint extrema,
per-sample capacity checks and minimum sampled margins must agree. All tested
start/midpoint/end motor and momentum demands must fit declared capacities.
Execution handoff uses the independently reconstructed finest configured cadence,
just as the declared state handoff does. Arithmetic comparisons use absolute
1e-8 tolerances in Nms/Nm; capacity crossing uses the model's 1e-12 allowance.

Intervals must cover the horizon, preserve every phase boundary and match saved
phase, scope and declared mode. Kinematics must be finite and normalized, and
attitude/rate continuous across intervals. Acceleration may switch at a phase
boundary. Analytic maneuver phases are evaluated independently with their original
clocks, including clipped source phases. Fixed-attitude activity poses are bound
to request inputs. Tracking poses are compared with activity-profile points at
matching epochs; intermediate resource poses remain declared kinematic evidence.
The checker does not derive tracking from spacecraft and Sun/target geometry.
A consistently fabricated path remains outside this validation boundary.

One wheel array per spacecraft and signed orthogonal coordinate wheel axes remain
the supported saved-plan scope. External unloading requires its explicit stationary
activity/mode and declared torque limits. Older moving artifacts without kinematic
evidence remain partial and should be regenerated. The older analytic stationary
checker remains available for stationary artifacts without that new evidence.

## Battery accounting

With constant declared bus generation, the checker partitions the horizon into
saved maneuver phases and activity intervals. Load is the sum of the declared
mode power and the phase's extra power. Terminal and transition modes may differ;
clipped phases retain the saved mode. Independent analytic Wh integration applies
charge/discharge efficiencies, capacity clipping, bus-side curtailment and unmet
demand. It checks every saved sample, initial/final balances, minimum energy,
reserve and complete interval coverage against that partition.

An execution prefix consumes only its executed interval. Planning retries have no
new execution prefix and cannot consume another interval of energy or momentum.
Solar-array generation and geometric eclipse/illumination power remain unsupported
by this independent battery checker. The resource runner's samples are comparison
evidence, never the source of truth for loads or balances.

## Evidence and reproduction

```sh
mix test.fast test/orbital_dynamics/mission_analysis/plan_validation \
  test/orbital_dynamics/mission_analysis/operations --max-cases 8

MIX_ENV=test mix orbital_dynamics.mission.operations \
  --scenario studies/motion_checkpoint_operations.json \
  --output-dir tmp/motion_resources
MIX_ENV=test mix orbital_dynamics.mission.validate \
  --operations-dir tmp/motion_resources --output-dir tmp/motion_resources_check

MIX_ENV=test mix orbital_dynamics.mission.operations \
  --scenario studies/execution_checkpoint_retry_operations.json \
  --output-dir tmp/constellation_resources
MIX_ENV=test mix orbital_dynamics.mission.validate \
  --operations-dir tmp/constellation_resources \
  --output-dir tmp/constellation_resources_check
```

Both examples pass native and independent checks. The constellation example
completes all six services/value 150 after failure and retry. The motion example
covers eleven checkpoints through hold, acceleration, cruise, deceleration,
settling, service, braking and return. A test inserts a failed-plan retry inside
committed motion and checks the full artifact chain.

The checker's independent equations also agree within 1e-5 Nms/Nm with all eight
[frozen body-frame RK4 cases](../../priv/validation/reaction_wheels/README.md) at
0.25-second intervals. These include unequal inertia, non-principal/changing-axis
rotation, signed/permuted axes and gyroscopic saturation. This is finite-case
numerical evidence, not a proof for every trajectory or a certification near
unsampled limits. Existing production-to-reference checks remain separate.

The five-case assessment also meets its expectations: both illumination and both
fixed-attitude cases pass independent checking. The hard work-cap case remains
partial solely for stopped operations, with three accepted completions and a stale
plan at that boundary.

Coherently rehashed artifacts with false wheel momentum, motor torque, limits,
kinematics, margins, phase labels, battery states or missing intervals are rejected.
A coherently shifted child state that passes standalone accounting still fails
parent-derived execution handoff. Historical observations retain their original
partial statuses. Current results are recorded in
[moving_resource_validation_observation.json](moving_resource_validation_observation.json).

Validation: full fast suite 5,466 passed/1,148 excluded (336.1 s, concurrently
with assessment); final focused checks 33 passed, plus six final mutation/reference
tests after initial-frame, quaternion and cadence refinements. Formatting and
whitespace checks pass. No historical maturity acceptance was changed.
