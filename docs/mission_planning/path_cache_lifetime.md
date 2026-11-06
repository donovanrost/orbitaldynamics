# Release path caches after final asset verification

Path-rule memoization is now partitioned by asset. Final horizon verification
releases each asset's partition after its terminal checks finish, including
supported, violated and unknown outcomes. Resource replay then starts without
path-cache entries. This reduces the live workspace identified in the
[memory attribution study](planning_memory_attribution.md).

Candidate search and final transition/horizon checks retain their original cache
hits. No entries are evicted while that asset can still need another path query.
The evaluator also releases any remaining partitions before resource replay,
covering workflows without a final horizon. Resource replay uses state,
pointing/kinematics and resource models rather than querying path rules.

Evaluation counters, captured rule sessions, policy and report evidence survive
release. Querying a released partition fails explicitly rather than reopening it
and silently consuming additional evaluation budget. Disabled path checking
remains a no-op. Release does not force garbage collection or change production
GC settings. Each evaluator trial starts from its immutable prepared empty cache,
so release in one trial does not retire assets in another.

The retained evidence policy is unchanged: complete final path, horizon and
resource histories remain available. This slice changes cache lifetime and
internal indexing, without reducing numerical fidelity, altering work ceilings
or introducing a new validation trust path.

## Verification

The opt-in paired verifier reloads only the path runner, horizon and attitude
evaluator from the supplied baseline source and current source, inside one
isolated VM. Both complete six-spacecraft/nine-request compact-opportunity reports
are **exactly equal as Elixir terms**, without deleting any fields. Canonical
whole-report digest:
`5ab2dc035d95e848246f95996fafc833916b39da8c548e82b2e10df86bf2735c`.
This includes every window, check, failure count, path-evaluation count, subsystem
sample, margin and assignment. Timing observations are separate from reports.
It is a software equivalence check, without independent physical validation.

The baseline copies of these three modules match commit `a8380c7c` exactly.
Other planner changes from the scaling/retention slices are present for both
implementations. Reproduce in fresh output directories:

```sh
mkdir -p tmp/path_cache_baseline
git show a8380c7c:lib/orbital_dynamics/mission_analysis/path/runner.ex > tmp/path_cache_baseline/path_runner.ex
git show a8380c7c:lib/orbital_dynamics/mission_analysis/attitude/horizon.ex > tmp/path_cache_baseline/horizon.ex
git show a8380c7c:lib/orbital_dynamics/mission_analysis/attitude/evaluator.ex > tmp/path_cache_baseline/evaluator.ex
MIX_ENV=test mix run dev/verify_path_cache_lifetime.exs tmp/path_cache_baseline tmp/path_cache_parity
MIX_ENV=test mix orbital_dynamics.mission.scaling --sizes 100 --requests 25 --output-dir tmp/path_cache_scaling
MIX_ENV=test mix run dev/profile_planning_memory.exs tmp/path_cache_retained 6 9 retained
```

The scaling result now records `path_rule_evaluation_count` separately from the
existing compact summary digest, making exact path work counts visible without
changing the digest's prior projection. The memory profiler accepts both legacy
flat caches and the new asset partitions, counting individual entries and
measuring the actual nested storage with sharing preserved.

Two new unit tests verify that release preserves another asset's cached hits
at an exhausted budget, retains provenance/counters, prevents reopening,
handles disabled checking, and keeps supported/violated/unknown final horizon
evidence and budget failures. Focused path/resource/horizon tests: 27 passed.

## Large-study observation

| 100 spacecraft / 25 requests | Before | After |
| --- | ---: | ---: |
| Sampled peak VM GB | 1.880 | 0.722 |
| Total planning seconds | 167.05 | 191.44 |
| Opportunity generation seconds | 129.79 | 146.87 |
| Scheduling seconds | 36.58 | 44.00 |
| Path evaluations | 613,893 | 613,893 |
| Scheduled requests | 25 | 25 |

The new case completes supported planning and resource replay, with identical
inputs and controls and the same compact result digest. All 2,500 pair searches complete under
the declared search policy. Sampled peak VM memory falls **61.6%** in these
individual local observations. This is a memory improvement; CPU-speed benefit
has not been established. The new run took longer, including its unchanged
opportunity phase, so the timings cannot isolate cache-management CPU cost.
The paired six-asset verifier also records timings, without a performance claim.

The earlier path count is established by the attribution run's 613,893-entry
flat cache: before eviction existed, each counted cache miss inserted one entry.
The new scaling output records the work counter directly, after all release.
The larger case checks compact result parity and path work count; the six-asset
verifier compares the entire report exactly.

The six-spacecraft retained-data diagnostic confirms that 74,868 path entries
remain available after candidate search and **zero** remain before/after final
resource replay. Its final report still measures 16,722,768 bytes of reachable
heap terms. Logical release does not force immediate reclamation: evidence may
share former result objects, other live references can persist, and heap capacity
can remain allocated until collection or process exit. No forced production GC
was added.

Host: Apple M1 / 16 GB, macOS 15.8, Elixir 1.20.4 / OTP 29. VM total is sampled
every second, not peak RSS; short peaks can be missed. There is one large timing
observation per version and no warmup. The paired verification and timed scaling
runs were completed separately from tests. This remains the synthetic clustered
250-second reference study, without operational acceptance.

[Durable observations](path_cache_lifetime_observation.json) preserve controls,
summary identity, counters, complete-report comparison, retained checkpoints and
source hashes. Full fast suite: **5,482 passed / 1,148 excluded**, 329.9
seconds. Formatting and whitespace checks pass. Local review covered the last
path-query boundary, disabled/unknown/violated cases, unchanged work charging,
per-trial isolation, retained evidence and the distinction between logical
release and physical reclamation. Historical maturity acceptance is unchanged.
