# Reusing validated campaign environment data

The campaign provider now retains one successful dataset admission per calling
process. The entry contains the exact complete immutable dataset and a local
validation-function identity. Repeated fetch, capability and provenance requests
for that same value skip semantic rehashing. Already-admitted product emitters use
the pinned semantic identity instead of independently rebuilding it several more
times per query. Interpolation and all physical models are unchanged.

The raw table still passes byte verification, parsing and source/coverage checks
when loaded. A new or changed in-memory dataset still passes the original
file-evidence and complete semantic-digest gates. Matching uses `===`, including
integer/float distinctions and all file-verification metadata; a claimed digest
or source revision is not a cache key. Failed admissions do not replace a valid
entry. An equivalent copied value may reuse admission; a different file path or
verification record triggers admission again and produces its own provenance.
Only one value is retained, so alternating valid metadata variants evict each
other. There is no global cache, ETS owner, server or cache invalidation service.
The entry is released with its process or replacement.

The local function identifies the executing validation code version. Unlike
querying the currently loaded module identity, it also stays associated with the
old code if an upgrade occurs during validation. A later call through new code
has a different identity and must admit the value again. The stored function is
never invoked. It can retain an old code reference until the next admission or
process exit; this is bounded to one entry. Tests exercise actual module reloads.

Request body/frame/time-scale/interpolation and finite-coverage checks still run
on every request. Cache state is internal process bookkeeping, not an
authentication boundary against arbitrary Elixir code running in that process.
As before, products describe the immutable loaded bytes; they do not reread a
changed file on disk on every fetch. Load the file again to admit new bytes.

## Verification

New trace tests observe the existing private semantic-hash function rather than
adding production counters. Repeated capability/provenance and both product types
hash once after load. They also cover numeric retyping, failed admissions, exact
copied values, one-entry eviction, per-process isolation, current file provenance,
query gates and code upgrades. Existing source-content, forged-dataset and malformed
container tests continue to apply.

```sh
mix test.fast test/orbital_dynamics/campaign_environment_provider_test.exs \
  test/orbital_dynamics/campaign_environment_validation_reuse_test.exs \
  test/orbital_dynamics/mission_analysis/physics_test.exs --max-cases 8
```

## Before/after planning comparison

The Rust experiment was reset to commit `78a30e61`, including its adapter-limit
changes and native build outputs. This change is pure Elixir and keeps the
original work ceilings. Its performance comparison uses the unchanged six-satellite,
nine-request, 250-second study and all original numerical/path/resource controls.
It does not mix timings from the differently configured larger Rust study.

The standalone benchmark reloads the original provider and current provider in
one isolated Mix VM, outside timing. It uses the real source filename so checked-in
data paths match. Two repetitions alternate baseline/reuse then reuse/baseline.
Full reports, hashes, counters, assignments and margins are saved. The planning
clock includes preparation, discovery, scheduling and final report assembly; the
separate workflow clock also includes encoding, compression, hashing and main-report
persistence. Compilation, tiny summary assembly/writing and warm-up are excluded;
no warm-up run is discarded. Avoid concurrent CPU-heavy work for timing runs.
This script is for an isolated benchmark VM, not a running application instance.

```sh
mkdir -p tmp
git show 78a30e61:lib/orbital_dynamics/environment/campaign_environment_provider.ex \
  > tmp/validation_reuse_baseline_provider.ex
MIX_ENV=test mix run dev/benchmark_environment_validation.exs \
  tmp/validation_reuse_baseline_provider.ex tmp/validation_reuse_comparison
```

Use a fresh output directory. These are local wall-clock observations, not latency
guarantees. Exact complete-report comparison establishes implementation parity,
not independent physical validation or mission acceptance.

## Observed result

On the same machine, two alternating-order observations gave these medians:

| Clock | Original provider | Validation reuse | Speedup |
| --- | --- | --- | --- |
| Planning | 19.49 s | 6.37 s | 3.06× |
| Through main-report persistence | 21.15 s | 8.04 s | 2.63× |

Independent streamed SHA-256 checking found all four complete uncompressed
reports byte-identical. Assignments, opportunities, sampling/callback counters,
checks and resource margins therefore match the original implementation. The
report is about 73 MB before compression in both cases. Individual timings,
input/report identities and controls are recorded in
[environment_validation_reuse_observation.json](environment_validation_reuse_observation.json).

Full fast suite: **5,471 passed / 1,148 excluded** (271.8 s). Five new trace
tests cover reuse and code-version admission; provider plus new tests: 14 passed.
Formatting and whitespace checks pass. No physical acceptance level changed.
