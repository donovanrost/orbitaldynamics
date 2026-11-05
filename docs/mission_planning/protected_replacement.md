# Protected commitments and bounded replacement

The planner can now treat selected activities as exact commitments while allowing
other selections to be replaced by more valuable work. Greedy remains the default.
The existing reassignment strategy still retains every served request by default.
The new `Scheduling.Replacement` strategy defaults to retaining only explicitly
protected placements.

## What protection means

Each protected activity declares exactly these fields:

```json
{
  "request_id": "middle",
  "asset_id": "a",
  "starts_at_s": 40,
  "ends_at_s": 50
}
```

Times use the mission's existing J2000 epoch origin and declared time scale. There
is no time conversion. The request must exist, its asset must exist, and its
interval must have the request's exact duration and fit within a current supported
opportunity. Only one protected activity per request is allowed. Overlap,
separation violations, and excess static resource costs are rejected.

The evaluator seeds these placements **before** greedy schedules tentative work.
This can give a different baseline from unconstrained greedy: a protected request
on spacecraft B stays on B even if greedy would otherwise put it on A. A protected
start is evaluated exactly and need not lie on the normal candidate-start grid.
All other activities remain subject to normal placement and feasibility checks.
Protected activities are marked `protected: true` in the selected report, and
`protected_selected` decisions identify their reserved opportunities.

For physical planning, protection requires an explicit horizon. Every protected
profile is built first, then its maneuvers and paths are checked against the full
protected neighbor set. Full resource timelines are replayed from the same
captured initial states. Checking only successive prefixes could incorrectly
reject a valid protected sequence because the partial prefix has a different
terminal/idle path. The implementation has a regression covering this case.

The protected set must be supported on its own under the configured constructed
paths and resource models. The planner does not search for optional services that
could rescue an otherwise unsupported committed path or energy timeline. Necessary
fixed supporting activities must be included in the protected set. Unsupported or
unknown protected geometry, paths or resources produce an error, not silent
removal, movement or acceptance. This is a conservative baseline requirement,
not a proof that no other supporting sequence could work.

The search controller independently checks protection after evaluation: exactly
one activity must exist for each protected request and its asset/start/end must
match. A duplicate protected request is rejected even if one copy matches. A
baseline mismatch aborts; an alternative mismatch cannot replace the incumbent.
Provider failures and exhausted subsystem budgets retain their existing error
behavior. Physical runs check fixed work through current models, including
endpoint eligibility. Static-only runs retain their sampled-opportunity, time-conflict
and declared-budget scope. Protection does not bypass the configured feasibility gates.

This is a planning constraint API for activities within the current horizon. It
does not import an approved operations plan, handle already-running activities,
or confer command/execution authority. Pointing and resource predictions are
recomputed; the protected contract covers request, spacecraft and timing.

## Replacement search

A proposal defers all opportunities of one tentative served request to the end of
the current order, retaining the relative order of the others. The shared
evaluator rebuilds the entire plan around the fixed commitments. The deferred
request can still be selected if it fits after other work. This permits one
served request to be displaced by several requests, without fabricating windows
or changing opportunity contents.

The deterministic neighborhood considers tentative requests in descending value,
then request-ID order. Previously evaluated orders are skipped. It accepts the
first strict total-value improvement whose full configured feasibility is
supported and whose commitments are intact. It then searches around that new
incumbent. Equal-value changes do not win. Trials include the baseline and remain
bounded to 1–64; each trial uses the existing subsystem limits and fresh evolved
state/counters while reusing the captured provider sessions. Protected seeding
work is repeated and charged within each trial's budgets. No global optimum or
exhaustive replacement claim is made.

`retention: :all_served` keeps the former rule even with the new strategy;
`retention: :protected` permits tentative selections to disappear. The controller
owns this gate, independently of strategy proposals. Reassignment and greedy
retain `:all_served` by default; replacement defaults to `:protected`. Exact
protected placements are enforced under either retention mode.

Search evidence records the retention rule, protected declarations, per-trial
added and removed request IDs, acceptance reasons, value and evaluation counts.
Only the selected proposal retains complete physical traces, as before.

## Use

```elixir
alias OrbitalDynamics.MissionAnalysis.Scheduling.{Policy, Replacement}
search = Policy.new!(Replacement,
  max_trials: 4,
  protected_activities: [
    %{"request_id" => "middle", "asset_id" => "a",
      "starts_at_s" => 40, "ends_at_s" => 50}
  ])
# MissionAnalysis.run(assets, requests, context, existing_opts ++ [scheduling: search])
```

The reference study JSON adapter accepts the named strategy and optional
protection/retention controls:

```json
"scheduling": {
  "strategy": "bounded_replacement",
  "max_trials": 4,
  "protected_activities": [],
  "retention": "protected"
}
```

Run the original constellation benchmark under replacement with:

```sh
MIX_ENV=test mix orbital_dynamics.mission.benchmark --sizes 6 \
  --strategy bounded_replacement --max-trials 4 --output-dir tmp/replacement_constellation
```

The repeated-service comparison now includes greedy, reassignment and replacement:

```sh
MIX_ENV=test mix orbital_dynamics.mission.workload --output-dir tmp/replacement_workload
```

Its custom `--study PATH` preserves the study's protected declarations for all
three orbital strategies. Strategy and trial controls are set by the comparison;
the independent small quality cases keep their own configurations and receive no
orbital commitments. The original benchmark input files and historical observations
are preserved.

## Known quality cases

The maneuver-gap case previously returned 10 while its independently enumerated
fixed-time optimum is 15. Replacement defers the middle request, allowing the two
outer requests to fit. Its selected plan reaches 15 with full configured attitude,
path, horizon and battery support. Protecting the middle request instead returns
10 with the original asset and interval intact; the unconstrained optimum no
longer applies to that protected problem.

The other fixed-time cases reach their existing optima: repeated assignment 27,
battery-limited 18, and battery-recovery 25. These small-case checks establish
quality under their declared ideal model, not an optimum for the orbital workloads.
Other regressions cover non-grid protected times, lower-priority commitments that
force assignment to another asset, multiple protected neighbors, initial provider
capture, static resource debits, invalid bounds, infeasible protected motion and
battery timelines, changed/duplicate placements, trial caps and retention modes.

## Initial measured comparison

Single observations on Apple M1 / Elixir 1.20.4 / OTP 29, eight online schedulers,
MIX_ENV=test, no discarded warm-up or simultaneous heavy test work. Runtime
includes opportunity generation and all bounded schedule trials, and excludes
artifact writing and standalone quality cases. There are no timing speed gates.

| Workload | Strategy | Value | Total runtime | Trials |
| --- | --- | --- | --- | --- |
| Original six-spacecraft, single-token case | Greedy | 159 | 18.86 s | 1 |
| Original six-spacecraft, single-token case | Replacement | 159 | 41.32 s | 4 |
| Three-spacecraft repeated service | Greedy | 130 | 18.36 s | 1 |
| Three-spacecraft repeated service | Reassignment | 130 | 70.07 s | 4 |
| Three-spacecraft repeated service | Replacement | 130 | 69.02 s | 4 |

No protected activities were supplied to these orbital comparisons. Replacement
hit the four-trial cap and preserved the incumbent in both workloads. In the
single-token case, its three alternatives scored 157, 158 and 157; in repeated
service they scored 126, 128 and 129. These are rejected lower-value proposals,
not evidence of global optimality. Both workload baselines and all accepted final
plans have supported configured physical evidence.

The six-spacecraft default greedy report and the repeated-service greedy report
were byte-identical to their pre-change versions. Activities, requests,
opportunities, decisions, complete selected attitude/path/horizon/resource
evidence and static balances were identical among the compared strategies on
each orbital workload. The independent small maneuver case is the demonstrated
quality improvement; larger workload gains remain an empirical question.

The complete compact observations, input configurations, trial counts, aggregate
model counts, independent oracle results and report SHA-256 digests are in
[protected_replacement_observation.json](protected_replacement_observation.json).
Local raw reports are under `tmp/protected_replacement_constellation/`,
`tmp/protected_replacement_greedy/` and `tmp/protected_replacement_workload/`.

Validation: 170 focused mission-planning/CLI tests passed, including exact
non-grid commitments, collective neighbor checks and independent controller
defenses. Frozen mission numerical baseline and independent read-only review
passed. The full fast suite with `mix test.fast --max-cases 8` passed **5,304 tests**,
with 1,148 excluded (201.6 s). No independent numerical reference data or acceptance
tolerances were changed.
