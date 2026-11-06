# 100-spacecraft scaling and hotspot observations

Historical baseline before [compact opportunity retention](opportunity_retention.md).
The scaling CLI now defaults to compact diagnostics; the commands below explicitly
select full diagnostics to reproduce the original retention policy.

The current planner completes a 100-spacecraft, nine-request analysis in **73.61
seconds**, with **3.20 GB sampled VM memory**. A 100-spacecraft, 25-request run
stops at the declared 6 GB memory ceiling before producing a completed plan.
Repeated JSON normalization is the next CPU hotspot; retained opportunity evidence
is also a scaling constraint worth addressing before further demand growth.

These are local observations on Apple M1 / 16 GB, macOS 15.8, Elixir 1.20.4,
OTP 29, eight online schedulers, starting from a8380c7c with the scaling harness
added. There is one unprofiled observation per size and no warmup. The durable
[data](constellation_scaling_observation.json) contains inputs' digests, compact
results, stack counts, controls, runtime and source hashes. This is an analysis
benchmark, without operational acceptance or independent physics validation.

## Reproduction and controls

Run each command in a separate VM, without concurrent tests or other benchmarks,
using a fresh output directory:

```sh
MIX_ENV=test mix orbital_dynamics.mission.scaling --sizes 6,25,50,100 --full-diagnostics --output-dir tmp/scaling_baseline
MIX_ENV=test mix orbital_dynamics.mission.scaling --sizes 100 --full-diagnostics --profile --output-dir tmp/scaling_profile
MIX_ENV=test mix orbital_dynamics.mission.scaling --sizes 100 --requests 25 --memory-mb 6000 --full-diagnostics --profile --output-dir tmp/scaling_demand
```

Defaults are nine requests, 900 seconds runtime and 6,000 MB sampled VM memory
per case. Maximum controls are 100 spacecraft, 100 requests, 1,800 seconds and
8,000 MB. Memory is sampled every second; the guard can overshoot and miss brief
peaks. It measures VM total memory, not process RSS or a hard OS quota. Failures
save available evidence, halt later cases and exit unsuccessfully. Expensive runs
remain opt-in and outside the fast suite.

The fleet repeats the original six spacecraft, adding 0.25 degrees of argument
of latitude and 0.01 hours of ascending-node local time per group. The first six
assets remain exact originals. Additional requests repeat the nine original
requests with unique IDs and corresponding activity-mode bindings. This gives a
nested, synthetic clustered workload over the original 250-second horizon, not
a global constellation design. Each asset has one service token. Fixed demand
isolates fleet cost and leaves most assets idle at larger sizes.

J2 propagation, scan resolution, event refinement, attitude, path, solar/battery
and terminal checks remain enabled. The scaling fixture explicitly declares
one-million evaluation budgets for attitude, path and resources. The finite
admission ceilings rise to 100 assets, three million sample/request pairs and
one million subsystem evaluations; existing study declarations/defaults remain.
Saved operations, snapshots and independent replay readers retain their separate
smaller asset bounds. The benchmark does not establish 100-asset replay support.

The complete report is still constructed **in memory**. The harness saves a
compact summary and avoids encoding/persisting the full diagnostic tree. Planner
clocks exclude compilation and persistence. Changing the saved output alone does
not resolve the in-memory evidence cost.

## Fixed-demand observations

All cases below completed opportunity searches and reported supported planning
and resource results.

| Spacecraft | Requests | Pairs | Scheduled | Opportunity seconds | Scheduling seconds | Total seconds | Sampled VM GB |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 6 | 9 | 54 | 6 | 3.05 | 4.48 | 7.62 | 0.28 |
| 25 | 9 | 225 | 9 | 12.28 | 6.42 | 18.74 | 1.07 |
| 50 | 9 | 450 | 9 | 26.37 | 13.10 | 40.04 | 1.79 |
| 100 | 9 | 900 | 9 | 50.24 | 23.19 | 73.61 | 3.20 |

Preparation and endpoint verification account for the remaining total time.
Opportunity generation grows approximately with pair count in this fixture;
these observations do not establish a general scaling law.

## CPU evidence

A full-call `mix profile.tprof` run on the original six-spacecraft case traced
586,464,865 calls over roughly 50 seconds. Instrumentation heavily changes timing:

- `JsonSafety.normalize_input!/2`: 659,858 calls.
- `TabularEarthOrientationProvider.fetch/2`: 129,243 calls.
- Its `normalize_sample/1`: 516,972 calls, corresponding to repeated preparation
  of a four-row table.
- `String.valid_utf8?/1`: 136,293,510 calls and 6.47 seconds of self time,
  12.98% of total traced self time.

A statistical profile at 100 spacecraft collected 2,992 stack snapshots:
`JsonSafety` appeared in 1,712 (57.2%) and tabular Earth-orientation code in 542
(18.1%). These are **overlapping inclusive stack observations**, not exclusive CPU
shares. Sampling uses a nominal 20 ms wait; actual cadence varies, and saved
stack depth limits attribution. Profiled planning took 74.51 seconds versus
73.61 seconds in the separate unprofiled run.

The two 100-spacecraft runs have equal input digests and equal compact summary
digests (`534f6d36e1ea51364847af8b36c8727da15d9336a7720fdf119440805f9dc2db`).
This checks the compact assignments, counters and battery-margin projection;
it does not compare every diagnostic sample or establish full report identity.

Source inspection identifies repeated construction of already-created model
`Evaluation` and path `Result` values at framework boundaries. Their constructors
recursively normalize checks/metrics again. Tabular Earth orientation separately
revalidates/remaps samples on rotation queries. Both are candidates for measured
reuse, preserving validation of changed, forged or raw inputs.

## Demand stress and next work

The 100-spacecraft / 25-request case reached **6.160 GB sampled VM memory** and
stopped after **162.534 seconds**, with status `memory_budget_exceeded`. It has no
completed summary or supported plan. Its 6,354 stack samples continued to show
JSON normalization prominently (3,869 inclusive samples).

This failure occurs even without encoding/persisting full reports. Opportunity
analysis retains dense per-pair event/function observations alongside search
and model evidence. The source structure and measured growth point to retained
evidence as the first memory target; a heap attribution profile would quantify
its exact share. Turning off the top-level sample list alone leaves nested search
observations intact.

Recommended next slices:

1. Bound or stream retained opportunity diagnostics after required audits. Keep
   complete failure/contradiction reporting, window results, coverage status and
   work counters; explicitly distinguish compact evidence from full diagnostics.
   Verify result parity and memory on the same fixed-demand and demand-stress cases.
2. Eliminate duplicate model-result normalization using a validated boundary or
   exact immutable admission mechanism. Preserve rejection of modified values;
   a struct type alone is insufficient evidence of validation.
3. Prepare and validate immutable tabular Earth-orientation data once, retaining
   all query-time coverage and frame/time checks.

No such optimization is included in this slice. Six harness tests cover fixture
nesting, demand bindings, finite budgets, saved memory failure, timeout cleanup
and invalid CLI controls. Focused checks: 10 passed / 1 excluded. Full fast suite:
**5,477 passed / 1,148 excluded**, 255.5 seconds. Historical maturity acceptance
remains unchanged.
