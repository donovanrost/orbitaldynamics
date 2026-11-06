# Planning memory attribution

Historical measurements before [path-cache lifetime changes](path_cache_lifetime.md).

The 100-spacecraft / 25-request study has a substantial live planning workspace,
and its sampled VM peak also includes transient allocation and garbage-collection
headroom. The completed report alone does not account for the roughly 1.9 GB
peak. All measurements here use compact opportunity retention with unchanged
physical/numerical controls.

## Method

The opt-in profiler recompiles three existing modules with temporary stage hooks
inside its own VM. It never rewrites production source or build artifacts, checks
that each injection anchor occurs exactly once and restores the original modules
when the run ends. Run commands separately, without concurrent benchmarks/tests,
using fresh directories:

```sh
MIX_ENV=test mix run dev/profile_planning_memory.exs tmp/memory_natural 100 25 natural
MIX_ENV=test mix run dev/profile_planning_memory.exs tmp/memory_retained 100 25 retained
MIX_ENV=test mix run dev/profile_planning_memory.exs tmp/memory_gc 100 25 natural_gc
```

`natural` samples VM categories, worker heap/process memory, stack and referenced
binary sizes every 500 ms, without forced GC. `retained` additionally collects
the worker at stage boundaries and measures selected reachable terms using
OTP's `:erts_debug.size_shared/1` in heap words. Component measurements preserve
sharing within each term, overlap one another and must not be added together.
Off-heap binary bodies are not included in term-heap sizes. Whole selected-term
unions are measured separately. Collection can resize a heap upward or downward;
a post-GC heap is allocated capacity rather than an exact count of live words.
The hooks and traversals can affect compiler liveness and execution behavior.

`natural_gc` traces worker collections with monotonic VM timestamps, brackets
worker inspection with two VM snapshots and keeps the 20 collections starting
with the largest combined young/old heap blocks. Tracing is diagnostic overhead.
VM/worker snapshots are sequential, not atomic: a process inspection can wait
for a collection to finish. Collection timestamps, heap-block sizes and the
second VM reading help explain discrepancies between consecutive measurements.
GC event heap sizes are words; the runtime reports eight-byte words on this host.

The driver enforces sampled 8 GB VM / 900-second guards and saves incomplete
status explicitly. These guards are not OS quotas and sampling can miss brief
peaks. Each completed run records a deterministic compact summary, which is compared
with the existing baseline in the observation evidence. The profiler is outside the normal test suite and does not
change production retention, cache lifetime or GC configuration.

## Normal execution

The first natural pass reproduced a **1.889 GB** VM peak during final
transition/horizon path checks, at about 170.6 seconds. Opportunity generation
peaked at **284 MB**. At the peak snapshot, 1.830 GB was in the VM's process
category; system memory was about 59 MB, including 6.9 MB of binary storage and
1.9 MB of ETS. Binary storage and ETS are therefore small contributors here.

The worker inspection taken immediately after that VM reading showed a 721 MB
process heap. Those are different moments, with GC able to run between them;
the difference must not be attributed to another component by subtraction.
The GC-traced follow-up below investigates this transient behavior.

## GC-traced follow-up

The GC-traced pass reproduced a **1.898 GB** peak in the same final-path stage.
The VM reading after worker inspection was **811 MB**, about 134 ms later;
the worker then reported **721 MB**. This demonstrates a large transient
component within a single observation window. The trace recorded 145 completed
major and 24,303 minor collections across the whole run. The saved largest-heap
subset does not contain every collection, so it does not establish an exact
byte-by-byte allocation to copying space at that peak. The observations are
consistent with allocation/heap-capacity and copying-collection overhead around
a much smaller live workspace. Forcing GC is not being proposed as the fix.

## Retained structures

A separate retained-data pass collected at stage boundaries:

| Boundary | Path cache entries | Path cache term MB | All evaluator-cache term MB | Worker process MB after GC |
| --- | ---: | ---: | ---: | ---: |
| Candidate search finished | 388,668 | 260.8 | 307.5 | 441.5 |
| Final path/horizon checks finished | 613,893 | 411.0 | 457.7 | 635.8 |
| Resource replay finished | 613,893 | 411.0 | 457.7 | 635.8 |
| Scheduler returned | Cache no longer returned | — | — | 367.9 |

The path cache stores complete rule results (checks and metrics), keyed by
asset, rule, epoch, quaternion and mode. Its map grows throughout candidate
search and final transition/horizon checks, including observations from rejected
candidate starts. There is no entry eviction during that evaluator invocation.
The final cache includes 204,621 entries for each of three rules (`sun_axis`,
`limb_axis`, `reflected_beam`) plus 30 service-mode entries. The 411 MB total
averages about 670 bytes per entry, including keys and map storage with sharing
accounted for. These are heap terms, not packed numeric records.

The `reflected_beam` group measures about 163.8 MB including its keys and result
objects; its metric substructure alone measures 76.9 MB. Each other geometric
rule group measures about 122.9 MB. These group figures overlap shared terms;
the combined cache measurement is the relevant total. The pointing/physical
cache separately has 61,260 entries and measures 36.9 MB.

The completed report measures **302.4 MB** of reachable term storage:

| Report component | Term MB |
| --- | ---: |
| Attitude-planning evidence, including horizon/resources/transitions | 240.3 |
| Horizon evidence | 143.1 |
| Resource evidence | 85.8 |
| Pair analysis evidence | 49.2 |
| Selection decisions after opportunity evidence attachment | 25.4 |
| Opportunity list | 18.1 |

Again these components overlap. Horizon evidence is part of attitude evidence,
and window/result objects are shared between several report sections.
They must not be summed as independent allocations.

After scheduler return, forcing collection reduces the worker allocation from
about **1,039 MB to 368 MB** in the instrumented pass. At report completion the
worker remains around 368 MB after GC, of which approximately 302 MB is reachable
from the report. The benchmark ultimately keeps only a compact summary and exits
that worker; the entire report is temporary analysis output in this harness.

## Next work

The next memory target is path-cache lifetime, especially entries from rejected
candidates and completed final checks. Final horizon processing adds about
150 MB to the path cache while retaining earlier entries. Any eviction scheme
must establish that later checks no longer need those entries or explicitly
account for repeated evaluations: cache misses currently consume work budgets,
so arbitrary eviction can change whether a study completes. Evidence sharing
and final horizon/resource histories are separate retained-data targets.

No cache eviction, forced production GC, reduced fidelity or lighter subsystem
evidence policy is implemented here. This slice establishes attribution before
choosing an optimization. Local host: Apple M1 / 16 GB, macOS 15.8, Elixir 1.20.4,
OTP 29. Figures use decimal MB/GB and are individual diagnostic observations,
without operational acceptance or independent physical validation.

## Verification and evidence

All three 100/25 diagnostic passes completed supported planning and resource
replay and matched the prior input digest and compact result digest
`fa9b57530645f10d664a3dcaa9dbe5d957917acc7644249fd0f9aaa6d7983e35`.
These digests cover assignments, counts and resource-margin summaries; they do
not establish full-report identity. Six-spacecraft retained and GC-mode smoke
runs also completed and matched their known compact summary. The retained smoke
exercised rule-group sizing; the GC smoke recorded 84 major and 4,681 minor
collection ends. Formatting and whitespace checks pass.

The [durable observations](planning_memory_attribution_observation.json) preserve
stage peaks, post-GC checkpoints, component measurements, rule counts, runtime,
source identities and result comparisons. Full local sample streams remain in
ignored `tmp/memory_probe_100_25_*/profile.json`. No production source changed in
this attribution slice. The previous 5,480-pass fast-suite result remains the
production-code result; the suite was not rerun for a dev-only diagnostic script.
No operational maturity or validation status changed.
