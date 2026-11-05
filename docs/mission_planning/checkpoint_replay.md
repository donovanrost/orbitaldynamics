# Checkpoint-faithful motion replay

Current validation follow-up: [moving resource validation](moving_resource_validation.md)
now covers saved moving-wheel histories and changing phase power. Earlier partial
results below remain historical; current regenerated examples pass the declared
resource-accounting scope. Orbit/pointing geometry and continuous feasibility
remain outside that scope.


An unchanged execution checkpoint now follows the accepted parent's saved motion.
It does not plan a new return to idle. The state at the checkpoint includes the
actual modeled attitude, angular rate, battery, wheel and temperature state along
that route. Moving the planning boundary is not itself a spacecraft maneuver.

This fixes the integrated illumination example's earlier checkpoint artifact:
the 330-second and 350-second cases now both complete all six services, with value
150. Previously the synthetic terminal return caused the later checkpoint to lose
one service. The older assessment observation remains a historical record; new
results are in `checkpoint_replay_observation.json`.

## What execution preserves

Replay retains exact placements for completed work and executed activity prefixes,
and clips the saved incoming/inter-activity/terminal motion to the checkpoint.
Clipped phases keep their original evaluation clocks, angular acceleration and
mode. Repeated checkpoints do not restart a slew, insert braking or settling, or
change which electrical/thermal mode applies to the already executed prefix.
Path, torque and resource checks still run against the saved motion; copying a
route does not waive constraints or convert unsupported physics into support.

`execution_boundary` is a finite endpoint carrying the declared attitude and
angular rate between activities. Like an activity checkpoint, it may carry
nonzero rate only at an exact boundary. It is not permission to hold a rotating
spacecraft indefinitely. Actual activity checkpoints retain their existing
`activity_boundary` behavior and original request clock.

The study's optional `saved_motion` stores compact kinematic intervals, their
modes and a content-bound source snapshot identity. It contains no copied path
sample reports. Original phase clocks remain flat across repeated slicing rather
than nesting complete historical reports. Existing JSON/input size bounds still
apply; an oversized or unsupported representation cannot become a usable child.

## Committed motion and tentative demand

A contiguous motion block already underway must finish under its original
profile. If that block is acquisition ending at a service, the destination
activity keeps its exact asset, start and end as a protected reservation. A new
outage or mismatched boundary state requires review instead of silently aborting
or replacing it. Completion credit and static costs still occur at the activity
boundaries, not when acquisition begins.

A braking block followed by an idle hold commits only the braking block. It does
not automatically commit a later acquisition separated by that hold. Work whose
acquisition has not begun remains tentative. Matching saved future routes can be
reused when their endpoints still match; changed tentative placements use the
ordinary constructive feasibility checks. An ongoing terminal return preserves
its remaining motion before newly planned work can start.

State updates explicitly confirm following saved motion with
`motion_source_snapshot_id`, which must equal their parent snapshot identity.
Prediction and unchanged synthetic execution stamp this automatically. An update
inside a maneuver without confirmation yields `in_progress_motion_unconfirmed`.
Confirmation is a declared fact, not an authenticated command acknowledgment.
Freshness/quality gates and attitude/rate continuity checks remain in force.
An acquisition already committed at an earlier boundary cannot later be declared
unexecuted without a separate abort contract.

## Explicit deviations and numerical scope

Scripts with `not_executed_request_ids` describe changed execution. They retain an
explicitly labeled `replanned_counterfactual_for_declared_skips` policy, rather
than claiming to follow the unchanged parent route. Their resulting counterfactual
path is checked, and they cannot silently abort previously committed acquisition.
The unchanged policy is labeled `follow_saved_parent_motion` in the chronology.
No live command or telemetry action occurs in either policy.

Motion checkpoints may fall between saved resource samples; in-activity
checkpoints still require an exact saved pointing sample.

The numerical invariant is preservation within stated tolerances, not bitwise
identity of all sampled reports. Geometry-dependent power and disturbance inputs
still use finite resource integration cadences; splitting an interval can change
quadrature error. Tests include phase-specific electrical loads, signed wheel
momentum, repeated boundaries, a checkpoint between original samples, unequal
inertia and a non-principal-axis slew with a rotated initial attitude.

Independent chain validation reconstructs interval ownership, mandatory
destinations, source identities and execution inputs from parent artifacts without
producer motion/history helpers. Its separate Hamilton phase evaluator checks
checkpoint attitudes and rates (quaternion components within 1e-12 and rates
within 1e-8 deg/s). A coherent rehashed child-source phase mutation can pass
standalone scope checks but fails parent-derived chain validation. This still does
not independently establish full orbital/path physics or moving-wheel dynamics.
Varying phase-load battery histories also remain outside the existing independent
constant-power envelope; supported stationary cases continue to pass.

## Reproduce

```sh
MIX_ENV=test mix orbital_dynamics.mission.operations \
  --scenario studies/motion_checkpoint_operations.json \
  --output-dir tmp/motion_checkpoints
MIX_ENV=test mix orbital_dynamics.mission.validate \
  --operations-dir tmp/motion_checkpoints --output-dir tmp/motion_checkpoints_check
mix test.fast test/orbital_dynamics/mission_analysis/operations/motion_checkpoint_test.exs
```

The eleven-checkpoint fixed-attitude example passes native lifecycle checks and
has explicitly partial independent validation for its moving/phase-load physics.
To rerun the integrated comparison, use the assessment command in
[constellation_assessment.md](constellation_assessment.md). Hardware parameters
remain synthetic. Successful original-profile continuation is supported; abort,
controller recovery and partial-service credit remain separate future contracts.
