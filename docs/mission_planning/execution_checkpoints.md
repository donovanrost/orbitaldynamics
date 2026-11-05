# Execution state independent of planning success

Current validation follow-up: [moving resource validation](moving_resource_validation.md)
now covers saved moving-wheel histories and changing phase power. Earlier partial
results below remain historical; current regenerated examples pass the declared
resource-accounting scope. Orbit/pointing geometry and continuous feasibility
remain outside that scope.


A validated execution update now produces an immutable execution checkpoint before
planning starts. Confirmed history, remaining balances, command receipts, ongoing
activity segments and committed motion survive a failed replan. The checkpoint
contains declared state and its source-bound context; it does not contain or claim
a feasible replacement plan.

`Advance.accept!(parent, update)` performs the existing state-shape, freshness,
quality, outcome and motion-confirmation gates, then prepares the state once from
its original parent. `Advance.plan!(parent, checkpoint, attempt)` plans from that
frozen boundary. `Advance.run!` remains a convenience returning both the checkpoint
and the planning result. The CLI and scenario runner persist the checkpoint before
calling the planner.

## Failure and retry behavior

A planning failure leaves the last accepted plan archived and marks it
`stale_pending_replan`. It is not an executable fallback at the new state epoch.
The latest accepted execution checkpoint and the old plan have separate identities,
epochs and histories. State that is physically finite but outside an operating
limit—for example battery energy below reserve—is retained even if every future
plan is unsupported. Malformed, stale or incomplete required state does not become
an accepted checkpoint.

A retry refers to the same checkpoint. It supplies an `attempt_id` and algorithm
controls (`strategy`, `max_trials`, optional `work_budget`). It cannot alter state,
receipts, existing commitments, request history, modes or availability. The
original horizon-extension/new-demand intent is reapplied as planning work after
state acceptance. An extension failure therefore also retains the checkpoint.

Verification reconstructs the checkpoint from its original parent to detect
coherently rehashed state changes. This is a read-only validation step, not another
execution replay or debit against the already updated balances. Every attempt
starts from the checkpoint's frozen inputs. Repeated failed attempts and a
successful attempt do not add completions, spend another token, consume more
energy or reset the modeled motion/temperature. A successful plan snapshot carries
`execution_checkpoint_id` to bind it to the state used for planning.

Retries retain the original observation epoch and provenance; they do not freshen
an old measurement or advance physical time. This is an offline artifact workflow,
not a live telemetry ingester, multi-writer state store or command executor. The
scripted driver requires a replacement plan before executing another interval
from a pending checkpoint. Only explicit `retry` steps may follow that pending
state; it does not silently execute the stale plan.

## Save and resume from disk

```sh
MIX_ENV=test mix orbital_dynamics.mission.checkpoint accept \
  --baseline tmp/baseline/baseline_snapshot.json \
  --update tmp/prediction/state_update.json \
  --output-dir tmp/accepted_state

MIX_ENV=test mix orbital_dynamics.mission.checkpoint plan \
  --baseline tmp/baseline/baseline_snapshot.json \
  --checkpoint tmp/accepted_state/execution_checkpoint.json \
  --attempt retry_attempt.json --output-dir tmp/retry_attempt
```

An attempt file can contain:

```json
{
  "attempt_id": "retry_with_larger_budget",
  "scheduling": {
    "strategy": "greedy",
    "max_trials": 1,
    "work_budget": {"max_evaluations": 200000}
  }
}
```

Use fresh output directories. Failed planning saves a review and any failed
candidate, leaves the input checkpoint unchanged, and produces no revised
snapshot. The existing `mission.revision advance` command also writes
`execution_checkpoint.json` before planning, including when planning later fails.
A checkpoint requires its original parent plan for semantic verification and
cannot be substituted for a plan snapshot. Checkpoint content identity is not
authentication. Artifacts are bounded to 8 MiB and existing JSON safety limits.

## Scenario reports and independent checks

Operations reports use `mission_operations_scenario.v2` for the changed acceptance
semantics and explicit retry events. Regenerate scenario artifacts for the current
checker; earlier observations remain historical evidence. Plan snapshots retain
their existing format.

The chronology distinguishes:

- `execution_epoch_s`: the synthetic execution clock;
- `accepted_execution_epoch_s`: the latest validated checkpoint epoch;
- `accepted_plan_epoch_s`: the boundary of the stored accepted plan;
- `final_accepted_execution_history`: the latest checkpoint's ledger;
- `final_plan_bound_execution_history`: the ledger associated with the stored plan;
- `plan_readiness`: whether a replacement exists at the accepted execution state.

Independent checking reconstructs checkpoint envelopes, accepted balances/history,
quality gates, parent bindings and retry controls without producer checkpoint or
acceptance helpers. It checks that retries neither replay execution nor advance
the clock, and rejects lost checkpoints, forged balances, changed commitments and
incorrect readiness claims. Existing physical-accounting limits remain explicit;
accepting declared execution does not establish telemetry truth or independently
validate moving-wheel dynamics.

## Reproducible examples

```sh
MIX_ENV=test mix orbital_dynamics.mission.operations \
  --scenario studies/execution_checkpoint_stationary_retry_operations.json \
  --output-dir tmp/checkpoint_retry_stationary
MIX_ENV=test mix orbital_dynamics.mission.validate \
  --operations-dir tmp/checkpoint_retry_stationary \
  --output-dir tmp/checkpoint_retry_stationary_check

MIX_ENV=test mix orbital_dynamics.mission.operations \
  --scenario studies/execution_checkpoint_retry_operations.json \
  --output-dir tmp/checkpoint_retry_constellation
```

The stationary example accepts a checkpoint inside service, fails at a one-call
planning budget, retries successfully and completes the original service once.
Its independent accounting passes. Tests also retain a command receipt and a
committed acquisition through failure/retry, and cover repeated failures and
attempts to mutate frozen state or constraints.

The three-spacecraft illumination example completes three early services, accepts
that execution state, then exhausts a 1,000-call replan budget. The accepted state
remains at +200 seconds while the old plan boundary remains at +0. A larger-budget
retry uses the same checkpoint, then the ordinary outage-restoration and execution
steps complete the remaining services. All six services close once. Independent
validation remains partial solely for the existing moving-wheel physics gap.

Recorded results and checkpoint identities: [execution_checkpoint_observation.json](execution_checkpoint_observation.json).
