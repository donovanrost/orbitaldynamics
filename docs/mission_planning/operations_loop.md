# Scripted execution and replanning loop

The operations scenario runner exercises planning, confirmed execution history,
state handoff, service availability and request explanations over several cycles.
It produces one chronological review plus reusable planning snapshots and separate
execution replay evidence. Scripts are deterministic, bounded to 16 steps, and
use the existing configurable reference adapter.

```sh
MIX_ENV=test mix orbital_dynamics.mission.operations \
  --scenario studies/operations_loop_scenario.json \
  --output-dir tmp/operations_loop
```

Open `tmp/operations_loop/README.md` for the chronology and `operations.json` for
changes, state packets, invariant results and request-level explanations. Use fresh
output filenames. The command rejects existing artifacts and preserves its inputs.
Each accepted snapshot can be inspected with the existing `mission.explain`
command or used as the baseline for another revision.

## Checked-in scenario

Three synthetic spacecraft each start with 10 Wh and two non-replenishing service
tokens. A 20 s service consumes one token and 2 Wh; all other modeled power loads
and generation are zero. The six requests occupy early and late windows in the
same 600 s horizon. Existing Earth/J2 trajectory, attitude and sampled path checks
remain enabled.

| Step | Scripted action | Observed outcome |
| --- | --- | --- |
| Commit services | Protect `early-1` and `late-2`. | Both exact placements become commitments. |
| First execution cycle | Execute ended services except `early-3`; advance to +200 s; subtract 7.5 Wh from demo-3's replayed energy. | `early-1` and `early-2` complete; `early-3` expires without completion. Future `late-1` moves to demo-1; `late-2` stays exact. |
| Service outage | Declare demo-1 service unavailable for the remaining horizon. | Tentative `late-1` is removed; future value changes from 43 to 21. |
| Service restored | Clear the unavailability set. | `late-1` returns; future value returns to 43. |
| Second execution cycle | Execute the remaining scheduled services; advance to +590 s. | Two more services complete; all demand closes as completed or expired. |

The run ends with four completed requests (value 102), one scripted skipped
service, and two expired requests. Remaining token balances are 0, 0 and 2;
energy is approximately 6, 6 and 2.5 Wh. The skipped service consumes no token or
service energy. Completed work never returns to active demand. An expired
unserved request is distinct from a scripted skip.

Changes occur under both the execution policy and injected state disturbances;
the chronology does not infer a single causal reason for every moved activity.
Full request explanations retain the tested constraints and search limits.

## Execution policy

At an `advance` step, every ended activity in the current accepted plan executes
as planned except the explicitly listed skips. This is an explicit synthetic
execution rule, not evidence that a scheduled activity executed in real life.
The runner builds a separate replay of the saved parent motion through the
checkpoint. [Checkpoint-faithful replay](checkpoint_replay.md) preserves ongoing
activity and maneuver profiles; declared skips use a labeled counterfactual route.
The replay must pass the normal attitude, path and resource checks before its
state can be used.

Battery energy comes from the exact terminal sample at the finest configured
resource cadence; attitude and rate come from saved motion or profile samples.
There is no battery interpolation. The replay excludes skipped work from its
activities and resource consumption. Static balances are reduced only for
executed services. A declared `energy_losses_wh` map then applies an external
state disturbance. Its physical cause is outside this simulation.

The resulting packet is validated and saved as an
[execution checkpoint](execution_checkpoints.md) before planning. Confirmed state
and history remain accepted when planning fails; an explicit retry can change
search controls without replaying execution. Ongoing activities and contiguous
maneuver blocks are preserved, and destination commitments are rechecked.

The final boundary leaves ten seconds for the remaining horizon, including the
current model's terminal settling allowance.

## Script contract

The script names `scenario_id`, `mission_manifest`, `planning_study` and `steps`.
Input paths are relative to the scenario file. Each uniquely identified step has
`kind`, `id` and `expected_status`.

- `revise` contains a normal native `change` object. It can select commitments,
  add demand or change the complete service-unavailable set using existing rules.
- `retry` names a pending execution checkpoint implicitly through the driver and
  supplies new algorithm controls; it neither replays execution nor changes state.
- `advance` declares `as_of_s`, `not_executed_request_ids`, `energy_losses_wh`,
  `protect_request_ids` and `scheduling`. Skips must name ended scheduled requests.
  Losses map spacecraft IDs to battery IDs and nonnegative Wh, bounded by replayed
  stored energy. The epoch must strictly advance within the original horizon.

Review status is checked against the scripted expectation. A non-ready plan
stops execution. When validated execution was accepted, explicitly following
`retry` steps may attempt planning from that checkpoint; other later steps remain
unprocessed until a replacement plan is accepted. An expected final conflict can therefore
produce `verification_status: passed` with `run_status: stopped_for_review`.
Exit zero means scenario assertions passed; it does not mean operations may
continue. A mismatched result, failed invariant or unprocessed step exits nonzero
after writing the review.

If execution occurred and subsequent planning fails, simulated time stays at the
new execution epoch. The previous accepted snapshot is retained with its older
planning boundary, alongside the independently accepted execution checkpoint and
execution replay. The runner
does not execute stale work or silently roll physical time back. Simulated
completions and completions recorded in the accepted ledger are counted
separately. Failed candidate reports are retained where the planner provided one.

## Checks and artifacts

Every accepted transition checks snapshot parent identity, persistent closed
requests, absence of closed requests from active/scheduled work, exact new and
inherited future commitments, service-unavailability exclusion and supported
remaining-horizon evidence. Advances also check monotonic time, independent
static-cost arithmetic, battery initial-state handoff and execution outcomes.
Ordinary revisions must retain the same state and planning boundary.

- `baseline_snapshot.json`: initial supported plan and inputs.
- `step-NN-execution_snapshot.json`: synthetic execution-only replay, when present.
  It is evidence for state generation, not the next adopted planning snapshot.
- `step-NN-execution_checkpoint.json`: validated execution state saved before planning.
- `step-NN-revised_snapshot.json`: accepted next planning snapshot.
- `step-NN-rejected_snapshot.json`: native snapshot rejected by driver invariants,
  if a regression causes that condition.
- `step-NN-failed_candidate.json`: unusable candidate evidence, when provided.
- `operations.json`, `README.md`: one chronology and its assertions.

Reports exclude wall timings so identical inputs produce identical semantic
reports and snapshot identities. This is a consistency regression harness using
shared feasibility models, not independent validation of spacecraft physics.
It adds no live telemetry transport, stochastic execution, approval or command
execution. In-progress activity/motion continuation and explicit horizon extension
are covered by the linked follow-up documents.

Recorded results are in [operations_loop_observation.json](operations_loop_observation.json).

Focused development check:

```sh
mix test.fast test/orbital_dynamics/mission_analysis/operations \
  test/mix/tasks/orbital_dynamics.mission.operations_test.exs
```

Use the [independent artifact checker](independent_plan_validation.md) to audit the
saved plan chain and simple power/token accounting without rerunning this simulator.
