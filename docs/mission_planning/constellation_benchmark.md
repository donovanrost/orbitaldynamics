# Small constellation benchmark

Run the full physical planner on nested fleets while holding requests and numerical
controls fixed:

```sh
MIX_ENV=test mix orbital_dynamics.mission.benchmark --output-dir tmp/small_constellation
```

Defaults are fleet sizes `1,3,6`, one run per size. Use `--sizes 6 --repeats 3`
for repeated observations, or `--sizes 1` for a shorter smoke run. Repeats are
bounded to 1–5 and fleet sizes to 1–6. This is an opt-in benchmark, outside the
fast development suite. Compilation happens before timing. There is no discarded
warm-up run; retain individual observations rather than comparing an unqualified
average. Avoid simultaneous CPU-heavy work when comparing timings.

`studies/small_constellation.json` declares six synthetic 600 km circular
sun-synchronous spacecraft with different orbital phases and ascending-node local
times. These are clustered spacecraft near one service region, not a global
coverage simulation. Nine requests compete at three sites over a 150 s service
window inside a 250 s planning horizon. Each asset has one non-replenishing
observation token. That deliberate constraint makes assignment matter and caps
fulfillment at the fleet size, independently of dynamic feasibility. Values are
synthetic utility units. These are assumptions for exercising software, not
Reflect Orbital requirements, spacecraft design estimates, or demand forecasts.

`studies/small_constellation_planning.json` makes the numerical and subsystem
assumptions explicit: 1 s J2 integration anchors/output, 2 s opportunity scans,
0.01 s root timing tolerance, 0.5 s inward margins, bounded attitude start search (5 s grid, at most 32 starts per opportunity),
initial and terminal orientations, path constraints, and battery replay at three
cadences with body-mounted solar generation and finite-Sun shadow contacts.
Every fleet size uses the same generic mission planner. No benchmark-only
assignment heuristic replaces the physical scheduler. The path and resource
budgets are each 100,000 evaluations across the whole plan, not per spacecraft.
The initial trial inherited a 50,000 path budget and aborted at six spacecraft;
that trial is excluded from the observations below. Exhaustion is a hard error,
not a supported result with silently omitted checks. Successful runs write
individual summary checkpoints so a later failure does not discard prior timings.

The output directory contains:

- `README.md`: runtime and fulfillment table.
- `summary.json` (and incremental `summary-N-R.json` checkpoints): every run's timings, value, assignments, opportunity and decision
  counts, model evaluation counts, and per-spacecraft minimum/final battery energy
  and reserve margin, plus full input configurations and runtime metadata.
- `report-N-R.json.gz`: complete planning report for size N, repetition R,
  including windows, rejections, attitude, terminal, path, and resource evidence.

The stage clock uses monotonic wall time. Preparation includes propagation,
sampler construction and policy preparation. Opportunity generation includes
model preparation, state/function evaluation, conservative window construction,
and opportunity evidence assembly for all asset/request pairs. Scheduling
includes greedy candidate search and final whole-fleet attitude/path/resource
replay. Endpoint verification is measured separately. Total also includes
validation, report assembly, and solar diagnostics; artifact encoding and writing
are outside the clock. Stage times are disjoint, but do not exhaust total time.
Raw reports remain deterministic; timing observations are returned separately by
`MissionAnalysis.run_profiled/4` and `Attitude.Reference.run_profiled!/2`.
Evaluation counters retain their original subsystem scopes and are not a total
count of every numerical operation. Battery margins are the lowest observed
energy over the tested cadences minus the declared reserve, not a continuous
physical guarantee. Unknown/violated planning evidence must still be inspected;
a selected request alone is not an acceptable mission plan.

## Exact tiny assignment checks

The benchmark also runs three synthetic one-slot assignment cases through the
production static scheduler and an independent exhaustive assignment enumerator.
Every request occupies the full slot, uses one token, and has explicitly allowed
assets. Enumeration considers every allowed assignment and skipping each request.
It is an exact oracle for these tiny cases only; it has no attitude, path, or
battery dynamics and cannot bound the physical benchmark's optimal value.

The flexible-request case has request `high` worth 10 available on assets A/B
and request `low` worth 9 available only on A. Value-first greedy puts `high` on
A, obtaining 10. Assigning `high` to B and `low` to A obtains 19. The independent
and single-slot-contention cases have zero optimality gap. These checks provide
a stable quality regression target before adding any reassignment algorithm.

## Interpreting scaling

This benchmark can establish a local runtime and identify a dominant stage. It
cannot establish a general constellation scaling law from three small fleets.
Pair count grows as assets × requests. State queries, constraint costs,
visibility, candidate start limits, and complete resource timeline replay also
matter. Clustered spacecraft and a single-token budget intentionally limit
schedule depth; this does not represent multi-orbit schedules with many
activities per spacecraft. Large-fleet behavior, global coverage, changing demand,
and continuous feasibility need separate studies.

## Initial observation

Recorded on 2026-11-02 (America/Denver), Apple M1, Elixir 1.20.4 / OTP 29,
eight online schedulers, MIX_ENV=test. One run per size, no discarded warm-up,
no simultaneous heavy test run. These observations are a starting point, not
runtime acceptance thresholds. The complete compact data and input assumptions
are retained in [constellation_benchmark_initial.json](constellation_benchmark_initial.json).
Full local reports are under `tmp/small_constellation_v1/`.

| Spacecraft | Pairs | Fulfilled | Value / 234 | Opportunity generation | Scheduling | Total |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 9 | 1 / 9 | 30 | 10.52 s | 0.73 s | 11.27 s |
| 3 | 27 | 3 / 9 | 86 | 54.26 s | 3.64 s | 57.91 s |
| 6 | 54 | 6 / 9 | 159 | 192.22 s | 16.87 s | 209.11 s |

All three runs reported supported horizon/path/resource planning under the
specified models. The lowest battery reserve margins across spacecraft and
tested cadences were 15.26, 13.88, and 13.58 Wh respectively. Opportunity
source/function evaluation counts were 33,120; 98,772; and 196,956. The
six-spacecraft run used 3,417 attitude model evaluations and 7,972 resource
model evaluations, as scoped by the existing subsystem counters.

The pair/evaluation counts grew roughly in proportion to fleet size, while
wall time grew faster in this small experiment. Opportunity generation accounted
for about 92% of six-spacecraft runtime. This supports profiling state/function
cache lookup costs and repeated geometry work before changing numerical fidelity
or adding a global optimizer; it does not establish which operation is responsible.
The exact toy cases separately confirm a greedy assignment quality gap (10/19
value in the flexible-request case). The physical benchmark has no optimality
oracle, so its unfulfilled requests do not establish an optimizer quality gap.

Validation: 137 focused mission-planning/CLI tests passed; the separate physical
benchmark regression and the frozen mission numerical baseline were also checked.

## Profiling and cache identity improvement

The next profiling pass used the same one-spacecraft end-to-end case under
Erlang eprof, with no profiler warm-up. Reproduce it with:

```sh
MIX_ENV=test mix profile.eprof --no-warmup --sort time --time 10000 -e '
alias OrbitalDynamics.MissionAnalysis.{ReferenceMission, ConstellationBenchmark}
mission = ReferenceMission.load!("studies/small_constellation.json")
study = ReferenceMission.load!("studies/small_constellation_planning.json")
ConstellationBenchmark.run_case!(mission, study, 1)
'
```

The initial profile attributed 23.14% of traced function time to `:maps.find/2`
and 19.35% to `:maps.put/3`. The event cache keyed queries by source/function
callbacks. These closures capture numerical samplers, including trajectory anchor
tables for the entire fleet. Hashing those environments on every cache access
made individual evaluations cost more as the fleet grew.

`EventSearch.Context` now keeps per-search source/function identity registries
and uses small integer identifiers in query-cache keys. Registry lookup compares
exact original callback identities rather than hashing their captured data.
Sources still distinguish sampler, frame, coverage and time scale; function
entries still distinguish ID, callback and complete input state. Struct updates
that change a callback get a different identity. IDs are scoped to one search
and discarded with its context. Unknown-result auditing retains its existing
numeric-equality matching of coverage representations. Nested evaluations and
budget accounting use the same shared context as before.

This changes neither numerical models nor discovery/search controls. The
registry uses linear lookup, suitable for the small sets of stable callbacks
used in these searches; a workload that constructs many distinct callbacks
inside a search would need separate profiling.

A repeat of the same unprofiled benchmark on the same machine produced:

| Spacecraft | Opportunities before → after | Scheduling before → after | Total before → after |
| --- | --- | --- | --- |
| 1 | 10.52 → 1.18 s | 0.73 → 0.70 s | 11.27 → 1.91 s |
| 3 | 54.26 → 3.52 s | 3.64 → 3.63 s | 57.91 → 7.15 s |
| 6 | 192.22 → 6.84 s | 16.87 → 12.33 s | 209.11 → 19.18 s |

These remain individual wall-clock observations, not speed gates or guarantees.
At six spacecraft, opportunity generation improved about 28 times and total
planning about 11 times. Opportunity work now grows approximately with pair
count in this small case; scheduling is the larger remaining stage at six assets.
The after-profile attributed 0.21% to `:maps.find/2` and 0.16% to `:maps.put/3`.
Profiler percentages include tracing overhead and describe the whole
one-spacecraft run, not isolated opportunity generation.

All three complete uncompressed planning report files were **byte-identical**
to their pre-change counterparts, including windows, decisions, assignments,
endpoint samples, evaluation counts, and attitude/path/battery evidence. The
compact observation and report SHA-256 digests are in
[constellation_benchmark_cache.json](constellation_benchmark_cache.json).
Local raw reports are in `tmp/small_constellation_cache/`; eprof output is in
`tmp/constellation_eprof_before.txt` and `tmp/constellation_eprof_after.txt`.

Regression coverage exercises callback factories with different captured values,
callbacks changed through struct updates, full input-state distinctions, source
coverage/frame distinctions, provenance-only changes, numeric coverage variants
in unknown audits, nested cache writes, shared budgets and exhaustion. All 51
event/opportunity tests and 27 validation/schema/candidate-refresh tests passed.
The independent event-reference and frozen mission numerical checks also passed.

The broader suite identified a stale generated artifact identity: candidate
refresh execution policies bind the executable BEAM digest of `EventSearch.Context`.
The deterministic validation rollup was regenerated only after confirming that
its complete decoded difference was the expected/observed policy fingerprint
and derived refresh ID for that single artifact fixture. The other 209 fixture
reports and every numerical value were unchanged. This preserves executable
identity enforcement; no independent reference data or tolerances were changed.

Final full fast-suite rerun after the derived fixture refresh: **5,271 passed,
1,147 excluded** (206 s). The physical benchmark remains opt-in.
