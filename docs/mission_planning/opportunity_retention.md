# Compact opportunity diagnostic retention

`MissionAnalysis.run(..., include_samples: false)` now releases dense opportunity
scan samples and complete-model observation traces after all required audits,
as well as omitting the top-level analysis sample list. Previously only the last
list was omitted. This bounds retained dense observations to the active pair
rather than carrying them through the entire fleet's planning and replay.

Full diagnostics remain the core and reference adapter default. The opt-in
scaling harness defaults to compact retention; `--full-diagnostics` selects the
historical policy. Generic mission callers can select compact retention with the
existing core option; `Attitude.Reference.run!/3` and `run_profiled!/3` now accept
the same `include_samples` boolean. Numerical controls and evaluation budgets do
not depend on retention mode.

## What remains available

Every scalar search, nested root/refinement evaluation, source gap audit,
complete-model contradiction audit and endpoint probe still runs. A failed model
observation inside an otherwise accepted window still vetoes the candidate.
Only after these audits does compact mode discard dense per-epoch records.
The caller computes the same sample counts and failed-check counts before
releasing its temporary sample list.

The retained report includes all conservative windows, root/event brackets,
limiting constraints, uncovered/unknown intervals, mission timing margins,
endpoint evidence, work counters, statuses and reasons. A rejected window keeps
its complete first contradiction. `opportunity_evidence.diagnostic_retention`
records the mode, audited model-sample count and first complete failed sample for
each check ID (at most the model's bounded check count). Failure counts remain
in the analysis summary. Retained examples supplement those counts; compact
mode does not retain every failing epoch. Raw function observations are omitted,
not replaced by an empty list implying no observations occurred.

Resource histories, attitude profiles, path checks, final fleet replay and
independent-validation inputs are unchanged. The event-search context and all
in-search caches remain unchanged and are restored/cleared by the existing
invocation boundary. No trust shortcut, skipped model validation or global cache
was introduced. This is a retention change, without a continuous-feasibility or
operational-acceptance claim.

## Reproduction

Run each benchmark separately, without concurrent tests, in a fresh directory:

```sh
MIX_ENV=test mix orbital_dynamics.mission.scaling --sizes 6,100 --output-dir tmp/retention_compact
MIX_ENV=test mix orbital_dynamics.mission.scaling --sizes 100 --full-diagnostics --output-dir tmp/retention_full
MIX_ENV=test mix orbital_dynamics.mission.scaling --sizes 100 --requests 25 --memory-mb 6000 --output-dir tmp/retention_demand
MIX_ENV=test mix run dev/verify_opportunity_retention.exs tmp/retention_parity
```

The verification script checks a canonical digest of the entire six-spacecraft
report after removing only analysis samples, event scan/function observations,
the event `include_samples` flag and diagnostic-retention metadata. All remaining
windows, events, unknown intervals, counts, schedules and complete subsystem
histories participate. It also records encoded report size and retained dense
observation counts. This is stronger than the 100-spacecraft compact summary
comparison, but neither establishes physical accuracy independently.

The [prior baseline](constellation_scaling.md) documents fixture scope and the
original memory failure. Measurements below are single local observations on
Apple M1 / 16 GB, macOS 15.8, Elixir 1.20.4 / OTP 29, eight schedulers, without
warmup. VM memory is sampled once per second, not peak RSS or a hard OS quota.
Timing differences are observations, not performance guarantees. Planner clocks
exclude compilation and report persistence. The older 25-request failure used
stack profiling; its elapsed time is not an unprofiled speed baseline.

## Observations

| Case | Retention | Planning seconds | Sampled peak VM GB | Outcome |
| --- | --- | --- | --- | --- |
| 100 spacecraft / 9 requests, prior | Full | 73.61 | 3.20 | 9 scheduled, supported |
| 100 spacecraft / 9 requests, current | Compact | 66.80 | 0.76 | 9 scheduled, supported |
| 100 spacecraft / 25 requests, prior profiled run | Full | Incomplete | 6.16 | Memory guard stopped case |
| 100 spacecraft / 25 requests, current | Compact | 167.05 | 1.88 | 25 scheduled, supported |

The nine-request case uses identical input digests and compact result digests
before/after. Sampled VM memory falls 76.2%; planning time falls 9.2% in these
single observations. Opportunity generation takes 44.62 seconds and scheduling
22.02 seconds in the new 100/9 case. The successful 100/25 case takes 129.79
seconds for opportunities and 36.58 seconds for scheduling, with supported
resource replay. It uses the same mission/study input digest as the earlier
failed case and the same 6 GB guard. All 900 and 2,500 pair searches respectively
report complete under the declared search policy. Diagnostic stack sampling is disabled for
the new timed run. There was no prior completed 25-request result to compare.

The six-spacecraft full/compact verification matches the entire outcome
projection, digest
`437471b3da9efb59d375af633aa74c20912ea2adee2ba06bc88450ce30d2d81e`.
Encoded report size falls from 72,827,405 to 19,446,662 bytes. Across its 54 pairs,
compact mode retains zero top-level model samples and zero raw function
observations, versus 8,442 and 8,334 respectively in full mode. Windows,
contradictions, failure counts, work counts and complete subsystem evidence
remain in the compared projection. Full reports intentionally differ in their
retained diagnostics; no full-report byte-identity claim is made.

The durable [observation JSON](opportunity_retention_observation.json) records
controls, summaries, parity scope, runtime and source hashes. The remaining
CPU target is repeated JSON validation/normalization, followed by tabular
Earth-orientation preparation. This slice does not change either.

## Validation

Two new analytic runner tests exercise full/compact outcome identity across
ordinary windows, unknown scalar margins, source gaps, timing-margin rejection
and a hidden contradictory refinement observation. They verify first-failure
examples against the full trace, omitted dense keys and unchanged bounded-budget
and invalid-declaration errors. A reference-adapter test rejects non-boolean
retention values before mission preparation. The focused opportunity/scaling/
benchmark run passed 25 tests. Full fast suite: **5,480 passed / 1,148
excluded**, 264.8 seconds. Formatting and whitespace checks pass. Local review
covered compaction after all audits, preserved raw-input validation, unchanged
query/work accounting, explicit retention controls and bounded representative
failures. No commit or push was made; historical maturity acceptance is unchanged.
