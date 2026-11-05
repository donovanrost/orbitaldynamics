# Replanning from an updated state

`mission.revision advance` moves the planning start to a declared common epoch,
keeps the original end, and recomputes the remaining plan. It accepts explicit
attitude, angular velocity, battery energy, remaining static budgets and execution
outcomes. It does not ingest telemetry or infer execution from a schedule.

## Runnable synthetic case

The one-spacecraft reference case schedules `early-3` and `late-1`. Its ideal
battery has 10 Wh capacity, a 2 Wh reserve, no generation, and a 360 W service
load. Other modeled loads are zero. Each 20 s service consumes 2 Wh. Two static
service tokens provide an independent check that completed work is not charged
twice and that balances cannot be reset.

```sh
MIX_ENV=test mix orbital_dynamics.mission.revision baseline \
  --study studies/rolling_state_planning.json --output-dir tmp/rolling_state_baseline

MIX_ENV=test mix orbital_dynamics.mission.revision advance \
  --baseline tmp/rolling_state_baseline/baseline_snapshot.json \
  --update studies/rolling_state_predicted.json --output-dir tmp/rolling_state_predicted

MIX_ENV=test mix orbital_dynamics.mission.revision advance \
  --baseline tmp/rolling_state_baseline/baseline_snapshot.json \
  --update studies/rolling_state_low_battery.json --output-dir tmp/rolling_state_low_battery

MIX_ENV=test mix orbital_dynamics.mission.revision advance \
  --baseline tmp/rolling_state_baseline/baseline_snapshot.json \
  --update studies/rolling_state_commitment_conflict.json --output-dir tmp/rolling_state_conflict
```

The last command deliberately exits nonzero after writing a conflict review.
Use fresh output filenames. The checked-in updates require the exact baseline
identity they were recorded against; changed planning evidence requires
regenerating the update and reviewing its declarations.

For a new synthetic update, without rerunning planning:

```sh
MIX_ENV=test mix orbital_dynamics.mission.predict_state \
  --baseline tmp/rolling_state_baseline/baseline_snapshot.json \
  --at 820497680.5 --output-dir tmp/rolling_state_prediction
```

This uses saved kinematic motion (or a saved activity-profile sample) and an
**exact supported sample** from each battery's finest reported cadence. It does
not interpolate battery energy, estimate missing coverage or claim telemetry.
It assumes ended baseline services executed as planned and subtracts their
static costs. Generated updates select no new commitments; edit
`protect_request_ids` if desired. Inherited future commitments always remain.

## Update contract

Every update declares these fields, with no arbitrary configuration overrides:

| Field | Meaning |
| --- | --- |
| `revision_id`, `source_id` | Stable identifiers for this revision and supplied state provenance. A label does not authenticate the data. |
| `expected_baseline_id` | Required exact parent identity; stale updates are rejected. |
| `as_of_s`, `time_scale`, `frame` | One strictly advancing epoch inside the existing horizon; UTC seconds since J2000 and `eci_j2000`. |
| `assets` | Exactly every baseline spacecraft, including service-unavailable assets. |
| `completed_request_ids` | Ended baseline services explicitly confirmed completed as planned. |
| `not_executed_request_ids` | Ended baseline services explicitly reported not executed. |
| `protect_request_ids` | Additional commitments selected from future baseline activities. |
| `scheduling` | Named strategy and bounded trial count for the remaining plan. |

Each asset supplies a unit `quaternion_wxyz` (active body-to-inertial),
`angular_velocity_inertial_deg_s`, a `battery_energy_wh` map keyed by every
configured battery ID, and `resource_budgets` with exactly the existing static
budget keys. Batteries must have finite configured capacities, and energy must
be between zero and capacity. Energy below reserve is accepted as a declaration;
the feasibility model must then assess it rather than silently repairing it.

Static budgets are remaining non-replenishing balances at the new boundary.
They can be lower than predicted, but cannot exceed the prior starting balances
minus confirmed completed costs. Those costs are not subtracted again during
remaining-plan scheduling. Battery energy is likewise a new initial condition;
there is no replay of earlier loads or charging.

The orbit's propagation epoch and trajectory definition stay fixed. Only the
planning boundary advances: re-epoching the circular-orbit manifest would reset
orbital phase. Terminal conditions, mode definitions, physical models, policies,
request definitions and service-unavailable spacecraft are retained. Requests
whose windows began earlier are still eligible for their remaining duration.
This operation adds no requests; use a subsequent ordinary revision to add demand.

## Execution history and review

Every ended baseline activity needs an explicit completed or not-executed
outcome. Missing outcomes produce `execution_history_incomplete`, with no planner
call or new snapshot. A baseline service strictly straddling the boundary produces
`in_progress_unsupported`, also before planning. An activity starting exactly at
the boundary is future work; one ending exactly there can be confirmed completed.
This version conservatively rejects a straddling baseline service even if the
caller believes it never started. Partial execution and deviations from the
baseline execution interval require a later extension.

Completed requests are removed from active demand and archived with their request
definition, baseline placement and declaration time. A request with less than its
required duration left in the horizon is archived as `expired`, separately from
completion. Skipped work stays eligible if its request window still permits a
full service. Active plus archived requests remain bounded to 100, with no ID
reuse. The latest raw update and its content identity are saved alongside this
ledger. Chained advances and ordinary same-horizon revisions preserve it.

Completed commitments retire into history. Future commitments retain their exact
spacecraft and interval and are rechecked from the supplied state. A missed past
commitment is explicitly listed in the review. A demonstrated protected placement
or resource violation produces `commitment_conflict`; unknown checks produce
`unsupported_revision`, and fatal provider/evaluation failures produce
`planning_failed`. None creates a usable child snapshot. Unknowns and budget
exhaustion are not treated as proofs that a commitment is impossible.

The ordinary diff compares **future baseline activities against the remaining
plan**. Completed and expired work is listed separately, so completion does not
appear as a scheduling removal and does not depress the future-plan value.
[Request explanations](scheduling_explanations.md) work on the resulting child.

## Observed outcomes

At the first service's end, predicted energy is approximately 8 Wh and one token
remains. Confirming that completion and protecting `late-1` retains its exact
placement. Declaring 2.5 Wh instead removes tentative `late-1`: a 2 Wh service
would cross the 2 Wh reserve. Protecting it produces a resource commitment
conflict with no child snapshot. An all-work-completed test still evaluates idle,
terminal and resource coverage through the original horizon end.

These cases check state handoff and lifecycle accounting within the declared
models. They do not validate spacecraft physics or actual execution. There is no
horizon extension, orbit-state update, uncertainty/staleness model beyond the
common epoch and parent ID, telemetry transport, operational approval or command
execution in this slice.

Recorded inputs and outcomes are in
[rolling_state_observation.json](rolling_state_observation.json).

The [scripted operations loop](operations_loop.md) exercises this handoff across
multiple cycles with execution replay, skipped services, energy changes and outages.

When an asset configures reaction wheels, its state packet also requires
`wheel_momentum_nms`, a map from every wheel model ID to three signed rotor
momenta in Nms. Prediction and execution replay populate this map; advancing
sets each model’s `initial_momentum_nms` without resetting stored momentum.
See [reaction_wheels.md](reaction_wheels.md) for the equations and examples.

[In-progress continuation](in_progress_activities.md) now supersedes the earlier
straddling-activity rejection: explicitly confirmed running work retains an exact
reserved tail and original identity. Existing unconfirmed boundaries still stop
for review. Horizon extension remains a separate development slice.
