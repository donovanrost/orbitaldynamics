# Automatic maintenance insertion

The optional scheduling maintenance search chooses from declared maintenance
requests and places them together with service activities. It can restore a
wheel-limited mission without a manually protected unloading reservation.
Its search mechanism is independent of the maintenance physics; each request
still needs a model, pointing, mode, duration, resource costs and allowed window.

## Run the reference mission

```sh
MIX_ENV=test mix orbital_dynamics.mission.operations \
  --scenario studies/automatic_wheel_maintenance_operations.json \
  --output-dir tmp/automatic_maintenance
MIX_ENV=test mix orbital_dynamics.mission.explain \
  --snapshot tmp/automatic_maintenance/baseline_snapshot.json \
  --request service --output-dir tmp/automatic_maintenance_explanation
```

Use fresh output directories. The baseline search rejects the 100 s horizon
without unloading: a 0.02 Nm disturbance demands 2 Nms from a 1 Nms wheel.
It then chooses a 20 s unload starting at 20 s from the allowed 20–60 s window.
The declared external torque is −0.055 Nm. The service at 70–80 s becomes feasible,
with final wheel momentum 0.9 Nms and battery energy 9.927777778 Wh.

Unloading consumes one maintenance token, reserves spacecraft time, draws 12 W
and incurs the same transition, path and terminal checks as other activities.
It does not reset momentum. Reference parameters are synthetic, not Reflect
Orbital hardware specifications. The operations scenario replans at 10 s, reviews the remaining plan in a
same-horizon revision, executes unloading before 60 s, then executes service
before 90 s. Wheel momenta
at these boundaries are 0.2, 0.1 and 0.7 Nms. Compact results are recorded in
[automatic_maintenance_observation.json](automatic_maintenance_observation.json).

## Declare choices and search limits

The example's [mission](../../studies/automatic_wheel_maintenance.json) declares
an ordinary zero-value `momentum_unload` request, with its duration and allowed
window. The [planning study](../../studies/automatic_wheel_maintenance_planning.json)
assigns its mode and enables this scheduling option:

```json
"maintenance": {
  "request_ids": ["unload"],
  "candidate_step_s": 5,
  "max_candidates": 16,
  "max_trials": 16,
  "max_insertions": 1
}
```

Only listed requests are optional maintenance choices. They are excluded from
the ordinary service pass and must have zero scheduling value. To offer different
durations or modes, declare separate request alternatives, each with its own
explicit duration, costs and mode assignment. With `max_insertions: 1`, the
planner can choose at most one. With a larger insertion cap, requests can be
combined as repeated maintenance; alternatives are not implicitly mutually
exclusive. A single request can execute only once.

Candidate starts use each supported opportunity's beginning, then the configured
step, plus its latest possible start if reached before the candidate cap.
Candidates are deterministic in opportunity start/asset/request/ID order. The
search first evaluates no optional maintenance, then single reservations, then
sets of two and three up to `max_insertions`. It checks overlaps, asset separation
and static budgets before invoking physical evaluation. All reservations in a
trial are present before service placement, so an individually infeasible prefix
does not prevent evaluating a feasible joint plan.

The candidate cap is 1–64, the insertion cap 1–3 and the trial cap 1–64, including
the baseline. Grid spacing is 0.001–86400 s. The product of maintenance
`max_trials` and ordinary scheduling `max_trials` must not exceed 64. Each joint
trial runs the configured service strategy with its existing evaluation budgets.
The report distinguishes a truncated candidate pool from a trial cap and from
exhaustion of the generated sets. None establishes global infeasibility.

A physically supported candidate can replace an unsupported baseline. Once a
supported plan exists, only greater service value is accepted; equal-value plans
keep the earlier incumbent. Thus unnecessary unloading is not inserted into an
already feasible plan. Existing service retention rules and exact user-protected
placements still apply. A violated or unknown candidate cannot become the
accepted plan. If every proposal fails, the original baseline's diagnostic result
or typed failure is returned; it cannot be adopted as a supported snapshot.

## Evidence and rolling state

`scheduling_search.maintenance_search` records reservations, accepted/rejected
status, service value, static costs, request outcomes and newly enabled service
IDs for each evaluated joint trial. `automatic_maintenance: true` marks selected
optional activities. These are tentative activities, not user commitments.
The internal evaluation uses exact reservations to assess each trial; the
returned `protected_activities` remain the user's explicit commitments.
The saved-request explanation command includes maintenance trials and limits.
The selected plan's full resource report contains battery and wheel histories.
`scheduling_search.work_accounting` now records callback counts across the entire
search, including failed service trials and endpoint verification. Each maintenance
trial also records its own `work_counts`, including zero-work reservation
rejections. The older inner service-search counts describe the chosen maintenance
trial; use `work_accounting` for total planning-search work.

An optional `scheduling.work_budget: {"max_evaluations": 10000}` imposes a shared
hard callback cap. Exhaustion stops search and retains a completely verified
incumbent if one exists. If no complete result exists, planning returns a typed
budget failure with its consumed-work evidence. An incomplete candidate is never
promoted. The budget covers uncached pointing/eligibility, path-rule, resource-step
and endpoint callbacks during scheduling. Initial propagation, opportunity
generation, model preparation and wall-clock time are outside this callback cap.
Per-trial subsystem limits continue to apply. State revisions inherit the budget
and may explicitly replace it in their scheduling controls.

Run the small-constellation accounting benchmark with
`MIX_ENV=test mix orbital_dynamics.mission.maintenance_benchmark --output-dir tmp/maintenance_work`.
It compares one/two spacecraft with uncapped and 1000-callback runs; raw timing is
an observation, not a latency guarantee. Recorded results are in
[maintenance_work_observation.json](maintenance_work_observation.json).

Same-horizon revisions inherit maintenance search settings. Advancing the
planning boundary carries the physical wheel state and remaining budgets,
retains open maintenance choices, and removes closed requests from those choices.
When no choices remain, the maintenance option is removed. Completed unloading
is archived and cannot be replayed. Execution replay runs selected activities,
not another maintenance search. Independent structural checking reconstructs
these changes. It now also checks stationary fixed-attitude wheel accounting,
including the example's unloading and state handoff. Moving wheel dynamics
remain **partial** in the saved-plan checker.

## Limits and checks

This is a bounded enumeration of declared choices. It does not derive unloading
attitudes, external actuator availability, torque direction, duration or costs
from spacecraft engineering data. The wheel model's sampled checks and declared
external torque assumptions still apply; see [reaction_wheels.md](reaction_wheels.md).
It does not continuously optimize maintenance timing, globally optimize a
constellation, infer causal guarantees outside evaluated trials, or generate
new maintenance requests from scratch.

Tests cover a successful automatic unload, duration alternatives, unavailable or
too-late maintenance, battery/static-budget rejection, mode gating, no gratuitous
unload, deterministic limits, protected services, two required maintenance
activities evaluated jointly, rolling revisions and execution replay.

```sh
mix test.fast test/orbital_dynamics/mission_analysis/scheduling/maintenance_test.exs \
  test/orbital_dynamics/mission_analysis/scheduling/maintenance_reference_test.exs
```
