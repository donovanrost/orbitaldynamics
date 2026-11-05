# Shared schedule evaluation and bounded reassignment

For exact protected placements and replacement of tentative work, see
[protected_replacement.md](protected_replacement.md). The priority-permutation
search below remains the foundation; protected placements are a separate fixed
reservation input to the shared evaluator.

Mission planning now separates opportunity generation, priority search, and
schedule evaluation. Omit `:scheduling` to use the original value-first greedy
behavior. The extraction preserves complete greedy report bytes for the existing
1/3/6-spacecraft benchmark, including decisions and numerical evaluation counts.

## Shared evaluation boundary

`Scheduling` establishes the canonical value-first opportunity order. Its trusted
strategy modules implement `Scheduling.Strategy.propose/4`. A proposal must be a
permutation of the original opportunity maps: a strategy cannot change a window,
forge an opportunity, duplicate it, or remove one. The controller validates this
before evaluation. Strategies propose; the controller owns the trial cap,
feasibility gates, acceptance rule, incumbent and audit trail.

An opportunity order is decoded into activities by the shared evaluators:

- `Scheduling.StaticEvaluator` places activities with conflicts, separation and
  static budgets. Its scope is explicitly `static_constraints_only`.
- `Attitude.Evaluator` searches the configured bounded start grid and evaluates
  tracking, acquisition, transitions, path constraints, whole-fleet terminal/idle
  coverage, and complete resource timelines. Path/resource sessions and initial
  states are captured **once** for the search, alongside the already prepared
  opportunity-model sessions. Every proposal starts from the same captured
  state and fresh static balances, dynamic state, caches and evaluation counters.

For an explicit search policy, the mandatory mission endpoint checks gate the
baseline and every proposal. Ineligible candidate endpoints reject the proposal;
provider errors abort analysis. The historical final endpoint verification is
retained. Alternative physical strategies require an explicit full planning
horizon. Unknown or violated whole-plan evidence cannot win a search trial.

This is an evaluator for **priority proposals with bounded time placement**,
not an API for arbitrary externally supplied activity times. Future fixed-time
or continuous optimization encodings will need another evaluation entry point.
The physical components can remain shared. No strategy changes the meaning of
feasibility or introduces command/execution authority.

## First search strategy

`Scheduling.Reassignment` explores a deterministic neighborhood. For each served
request, in descending value and then request-ID order, it tries preferring an
opportunity on another asset. The selected alternative is moved ahead of that
request's other opportunities; all other relative order is retained. Candidate
placement and subsequent assignments can change when the whole proposal is
replayed. A preferred alternative that fails checks can fall back to the
request's original opportunity.

A proposal replaces the incumbent only when all three conditions hold:

1. Its configured whole-plan feasibility gate is supported (or explicitly static-only).
2. It retains every request served by the incumbent.
3. It strictly increases total fulfilled request value.

The search uses the first improving trial and continues around the new incumbent.
It skips previously evaluated orders. It does not change request priorities,
remove served requests, cross equal-value plateaus, or enumerate all assignments.
A failed move does not prove no feasible alternative exists. This is local
reassignment with a conservative service-retention rule, not a global optimizer.

## Bounds and evidence

`max_trials` is explicitly 1–64 and **includes the greedy baseline**. A cap of
four permits at most three alternatives. Hitting the cap returns the already
verified incumbent with `trial_limit_reached`. Exhausting this strategy's current
neighborhood reports `neighborhood_exhausted`; this is not a completeness claim
about continuous schedules or the global assignment space.

Opportunity geometry is generated once. Each schedule trial has the same
configured start-grid, attitude, path, and resource limits. Those evaluation
budgets reset per trial, making the aggregate bound the trial cap times the
per-trial limits. Endpoint verification adds at most two model evaluations per
selected activity per trial, plus the checked state/lookback queries and the
final verification. Limits on scan/profile sizes still apply. There is no hard
wall-clock deadline and the trial cap does not bound a custom strategy's own
computation time. Providers must remain deterministic after session capture.

Provider errors and exhausted subsystem evaluation budgets abort analysis; they
do not silently return an incumbent as if the alternative was infeasible. Search
trial exhaustion is the explicit, separate fallback condition.

The top-level `scheduling_search` report records strategy, proposal encoding,
cap, trial count, termination, baseline/final value and every trial's acceptance
reason, feasibility, selected count and attitude/resource model counts. The
aggregate counters include rejected proposals. Normal attitude/resource evidence
and counters describe the **selected** proposal only. Endpoint evaluations and
opportunity evaluations have their own scopes; the aggregate model counters are
not a count of every numerical operation. Rejected proposals' complete physical
traces are not retained. The selected proposal's full evidence is retained.

## Use

Trusted Elixir callers can configure a strategy through the generic mission API:

```elixir
alias OrbitalDynamics.MissionAnalysis.Scheduling.{Policy, Reassignment}
search = Policy.new!(Reassignment, max_trials: 4)
# MissionAnalysis.run(assets, requests, context, existing_options ++ [scheduling: search])
```

Reference attitude study JSON accepts the optional block below. JSON maps only
these named strategies to trusted modules; it cannot load arbitrary modules.

```json
"scheduling": {"strategy": "bounded_reassignment", "max_trials": 4}
```

`"greedy"` and `"bounded_replacement"` are the other supported names. The default remains greedy without the
extra search-report section. An explicit greedy policy reports one baseline trial.
Run the existing constellation case under both strategies with separate output
directories:

```sh
MIX_ENV=test mix orbital_dynamics.mission.benchmark --output-dir tmp/scheduling_greedy
MIX_ENV=test mix orbital_dynamics.mission.benchmark --output-dir tmp/scheduling_reassignment \
  --strategy bounded_reassignment --max-trials 4
```

## Quality and regression checks

The original static flexible-request trap improves from value 10 to its exact
single-slot optimum of 19. The independent and single-slot-contention cases retain
zero gap. A second synthetic two-asset regression demonstrates the same 10→19
improvement using the production attitude/path/horizon and battery evaluators.
It also checks that changing preparation revisions are captured once and that
battery state resets independently for every proposal. Low battery reserve and
violated/unknown path variants prevent the attractive move. Controller regressions
cover ineligible endpoints, provider errors, unsupported fleet evidence, served
request retention, forged proposals, determinism and the baseline-inclusive cap.

The constellation fixture gives each asset a single token and greedy already
uses all assets. The retention rule cannot exchange a served lower-value request
for another request, so value improvement is not expected on that saturated case.
Its role here is measuring overhead and preserving full physical evidence. The
physical fixture has no global optimality oracle.

## Initial measured comparison

Single observations on the same Apple M1 / Elixir 1.20.4 / OTP 29 setup,
MIX_ENV=test, no discarded warm-up. Timings include the full pipeline but exclude
artifact encoding/writing. They are observations, not performance acceptance gates.

| Assets | Greedy value | Reassignment value | Greedy total | Reassignment total | Schedule trials |
| --- | --- | --- | --- | --- | --- |
| 1 | 30 | 30 | 2.04 s | 1.86 s | 1 |
| 3 | 86 | 86 | 7.83 s | 17.72 s | 4 |
| 6 | 159 | 159 | 18.99 s | 54.10 s | 4 |

The three/six-asset searches reached the four-trial cap and retained the verified
greedy incumbent. Their total attitude model counts were 4,552 / 14,608 and
resource model counts 15,920 / 31,888. In comparison, greedy used 888 / 3,417
attitude and 3,980 / 7,972 resource evaluations. Opportunity evaluation counts
were identical between strategies: 33,120 / 98,772 / 196,956 for 1/3/6 assets.
The one-asset case has no alternative asset and terminates after its baseline;
its small apparent timing reduction is measurement variation.

All six results reported supported configured physical planning checks. For every
fleet size the final activities, opportunities, requests, decisions, full attitude,
horizon/path/resource evidence and static balances were identical between the two
strategies. Every default greedy report was also byte-identical to its pre-extraction
counterpart. The compact recorded measurements, exact tiny-case results, input
configurations and full-report SHA-256 digests are retained in
[scheduling_comparison.json](scheduling_comparison.json). Local compressed reports
are in `tmp/scheduling_greedy/` and `tmp/scheduling_reassignment/`.

Validation: 149 focused mission-planning/CLI tests passed, including 12 search
and physical regressions; frozen mission numerical baseline passed; independent
read-only review found no remaining blocker. Full fast suite with
`mix test.fast --max-cases 8`: **5,283 passed, 1,147 excluded** (204 s).
The first run at the default 16 concurrent cases passed 5,282 tests but hit the
existing campaign file-backed schema test's 60 s deadline; that test passed in
isolation in 12.6 s. The eight-case rerun retained its assertions and timeout.

The original reassignment policy retains every served request by default. The
new replacement policy can release tentative selections while preserving exact
commitments; its scope and new fixed-time evaluation entry point are documented
in [protected_replacement.md](protected_replacement.md).
