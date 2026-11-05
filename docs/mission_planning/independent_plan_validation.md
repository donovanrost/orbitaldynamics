# Independent plan and accounting validation

The offline checker reads saved reference snapshots and operations artifacts. It
implements its own structural rules and analytic energy arithmetic without
calling the planner, commitment validator, execution replay, attitude/path checks
or resource runner. JSON encoding/decoding and SHA-256 use the standard runtime.
It validates consistency with declared inputs, not the truth of those inputs.

## Run

```sh
MIX_ENV=test mix orbital_dynamics.mission.validate \
  --snapshot tmp/operations_loop/baseline_snapshot.json \
  --output-dir tmp/independent_snapshot_check

MIX_ENV=test mix orbital_dynamics.mission.validate \
  --operations-dir tmp/operations_loop \
  --output-dir tmp/independent_operations_check
```

Generate the input directory with the [operations loop](operations_loop.md).
Validation does not propagate or schedule anything. Both commands write
`validation.json` and `README.md` using fresh output filenames, and preserve the
input artifacts. Parsing rejects duplicate keys, malformed/trailing JSON and files
larger than 64 MiB. Operations loading uses fixed artifact filenames and a bounded
16-step chain; it does not follow arbitrary paths in report metadata.

Results are `passed`, `failed`, or `partial`. A partial result means some checks
are unsupported or operations are stopped for review. Both failed and partial
results exit nonzero after writing evidence. Missing input artifacts produce a
failure report. A pass covers the listed checks; it is not mission approval.

## Structural and lifecycle checks

The checker independently verifies snapshot content identity, schema version,
reference input/report bindings and declared time-system consistency. It checks
active request/spacecraft identities, one selected activity per request, allowed
windows, requested duration, horizon bounds, spacecraft overlaps and separation,
reported request statuses and values, exact protected placements, unavailable
spacecraft exclusion and static resource balances.

Closed request identities must be unique and absent from active/scheduled work.
Completion placements must fit their archived request and precede the declaration
time. Expired work must actually have insufficient duration remaining. The raw
state update, its digest, the ledger boundary and the new initial state must agree.

For an operations chain, the checker follows parent identities and reconstructs
allowed changes from the original script. It compares those inputs with accepted
snapshots, including inherited commitments and history. It derives the executed
prefix from the parent schedule and explicit skips, rather than trusting the
runner's `checks`, `executed_services` or cumulative totals. Static costs are
subtracted once from the previous boundary's balances. Completed and expired
requests are reconstructed independently and cannot silently disappear or return.
Chronological plan summaries and final counts must agree with the checked files.

## Analytic battery model

Battery checks require finite known capacity, initial energy, reserve and
efficiencies, constant known bus generation, and complete nonnegative mode/phase
loads. The checker independently partitions saved phases and activities, integrates
Wh with clipping, curtailment and unmet demand, and verifies every diagnostic
sample plus aggregate balances, minimum energy and reserve. Idle and terminal
loads may differ. Executed prefixes are checked separately from future forecasts.
Solar geometry and unknown generation remain unsupported.

## Reaction-wheel accounting through motion

Current artifacts include the exact start/midpoint/end kinematics used by wheel
resources. The checker independently accumulates global inertial angular impulse,
subtracts body angular momentum, projects onto wheel axes and evaluates Euler
motor demand. It checks every cadence, saved state, midpoint metric, sampled
capacity margin, endpoint extrema and execution handoff. Saved maneuver phases
are evaluated with original clocks; activity poses bind to declared inputs or
matching saved profile points. Intermediate tracking poses remain declared input,
not independently derived pointing geometry.

One three-wheel array per asset with signed orthogonal coordinate axes is
supported. Older moving artifacts without kinematics remain partial; older
stationary fixed-attitude artifacts retain analytic checking. See
[moving_resource_validation.md](moving_resource_validation.md) for equations,
evidence, tolerances, reproduction commands and the sampled validation boundary.

## Mutation evidence

The checker passes the saved three-spacecraft operations chain. Deliberately
corrupted copies are rejected for shifted commitments, reintroduced completed
demand, token overspending and falsified final battery energy. Their content hashes
are recomputed with the producer's JSON encoder before checking, so these tests
exercise semantic rules rather than just checksum rejection.

A further case coherently changes a final snapshot and its raw state packet to
charge a skipped spacecraft for phantom work. That snapshot is internally
consistent and passes alone. Checking the chain rejects it because parent balances
and actual execution imply a different result. This distinguishes single-plan
consistency from execution-history accounting.

Tests also cover capacity clipping and charge/discharge efficiencies using a
hand-calculated case, unmet bus demand, falsified chronological summaries,
unsupported models, stopped operations, missing artifacts and malformed files.
Recorded outcomes are in
[independent_plan_validation_observation.json](independent_plan_validation_observation.json).

## Limits

A whole chain can be consistently fabricated; content integrity is not
authentication or execution evidence. Orbital dynamics, visibility/opportunity
completeness, pointing geometry, actuator hardware, continuous maneuver/path feasibility and optimization quality remain
outside this checker. The producer's feasibility labels are not independent
physical evidence. A stopped operations run is reported as partial even when its
expected-failure scenario assertion passed: it has no newly validated operating
plan at that boundary.

Focused development check:

```sh
mix test.fast test/orbital_dynamics/mission_analysis/plan_validation \
  test/mix/tasks/orbital_dynamics.mission.validate_test.exs
```
