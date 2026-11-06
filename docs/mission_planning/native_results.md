# Native path and resource results

The subsequent [domain-admission slice](domain_admission.md) moves generic
recursive diagnostic checks from callbacks to output boundaries. Measurements
and conservative-guard descriptions below record this original migration.

The first native-result slice separates path/resource computation from JSON
report projection. Path checks are `Path.CheckResult` structs with atom outcomes,
explicit margins/units and model-owned details. `Path.Result` retains those
checks and native metrics. Metrics and resource states can be native structs;
tuples and atoms remain native until report projection.

Built-in path/resource callbacks now construct native checks directly and return
raw `Result` values using `build/2` or struct construction. The runner admits each
fresh callback return using `Result.validate!/1`, without reconstructing it or
calling JSON normalization. Admitted internal cache hits are reused directly.
The optional `new!/2` convenience constructor admits immediately; callbacks can
avoid that duplicate admission by returning a raw native result instead.

Admission still checks nonempty/unique IDs, three-valued outcomes, paired margin
values/units, finite bounded margins, bounded payload depth/node/collection/text
sizes and unsupported opaque terms. A struct tag alone is insufficient: forged
or modified callback values still pass through admission. Domain payloads retain
their original representations; admission returns the same values and does not
stringify atoms. Resource-state admission similarly preserves the state object.

```elixir
%Result{
  checks: [
    %CheckResult{
      id: "battery_reserve",
      status: :supported,
      margin: 12.0,
      margin_unit: "Wh"
    }
  ],
  metrics: %MyMission.BatteryMetrics{power_w: 150.0}
}
```

`Result.outcome/1` provides the native aggregate outcome. `status/1` retains the
existing string outcome for the outer planning/evidence interfaces, which have
not all been migrated to typed objects. Flexible built-in metrics and state maps
also remain supported; this slice does not introduce a separate metric/state
struct for every built-in physical model.

## Report projection and memory

`ReportData` explicitly projects native values into JSON-compatible report
values. Check fields map to the existing saved-report schema, tuples become
arrays, ordinary atom values become strings and native nil becomes JSON null.
An explicitly unknown check margin uses native `:unknown` and projects to null.
The core public planning API still returns the existing report format. Saved
readers, snapshots and independent checking therefore receive the same shape.

Projection happens when evidence ownership closes. Final terminal-path evidence
is projected per asset after its last path query; final resource model histories
are projected after each asset's replay finishes. These closed partitions are
reused during whole-report assembly. Detailed failure explanations have their
own explicit check projections. Computational callbacks and caches retain native
checks; they do not receive projected report values for subsequent physics.

Completed partitions use an internal `ReportData.Completed` wrapper. Fresh
callback-data admission rejects this type, including nested/forged instances.
This is an internal output boundary, not a result-validation marker models can
set. No global validation cache or opaque trusted callback flag was introduced.

A monolithic whole-fleet projection initially reached 2.23 GB sampled VM memory
on the large case; the final design projects closed asset evidence separately.
The projection avoids rebuilding unchanged report branches and unwraps already
projected partitions at the public output boundary. It still validates output
text, rejects ambiguous atom/string field aliases and rejects unsupported terms.
Finalization phases also tail-call separate helpers, allowing earlier cache
versions to become unreachable before later phases run. Horizon completion also tail-calls its continuation,
which captures final output but not the incoming cache; each asset is finalized
by a tail-recursive ownership loop. A six-asset retained
probe reduced post-GC worker allocation before resource replay from 59.5 MB to
28.7 MB and after replay from 71.3 MB to 19.9 MB. Those are diagnostic observations,
not production GC changes. No production garbage-collection setting was changed.

## Equivalence and reproduction

The opt-in verifier compares a supplied pre-migration source snapshot with the
current implementation in an isolated VM. It reloads only changed production
modules and restores current modules afterward. The entire six-spacecraft,
nine-request compact-opportunity report matches exactly as an Elixir term,
without excluding fields, canonical digest:
`5ab2dc035d95e848246f95996fafc833916b39da8c548e82b2e10df86bf2735c`.
All windows, margins, histories, assignments and work counts participate. This
checks software equivalence, not independent physical accuracy.

```sh
# Preserve the pre-migration lib/ tree before applying this slice.
MIX_ENV=test mix run dev/verify_native_results.exs tmp/native_results_baseline tmp/native_results_verify
MIX_ENV=test mix orbital_dynamics.mission.scaling --sizes 100 --requests 25 --output-dir tmp/native_results_scale
```

The baseline is the preceding path-cache-lifetime implementation, including the
uncommitted scaling and opportunity-retention work. Source hashes in the durable
observations identify it. Compilation, profiling and artifact writing remain
outside the planner clock; public report projection is inside total planning
time. Timed large runs and tests run separately.

## Remaining migration

Mission `Evaluation` objects, opportunity/event metadata and tabular environment
preparation retain their previous normalization paths. Configuration and external
JSON admission remain separate, intentional boundaries. Outer evidence/report
maps have not all become typed domain objects. This first slice covers native
path/resource checks, result admission, resource-state handling and explicit
projection; it does not claim to eliminate all JSON work during planning.

Next slices can migrate mission evaluation checks and event observations to
native types, then introduce model-owned metrics/state structs where those
clarify their contracts. Numerical/physics validation and operational maturity
status are unchanged by this representation migration.

## Observations

| 100 spacecraft / 25 requests | Before | Native result pipeline |
| --- | ---: | ---: |
| Total planning seconds | 191.44 | 155.53 |
| Opportunity generation seconds | 146.87 | 128.34 |
| Scheduling seconds | 44.00 | 25.85 |
| Sampled peak VM GB | 0.722 | 0.881 |
| Path evaluations | 613,893 | 613,893 |
| Scheduled requests | 25 | 25 |

The final case reports supported planning and resources with identical inputs,
controls and compact result digest. All 2,500 pair searches complete under the
declared search policy. Memory increases by about 160 MB versus the previous
cache-lifetime observation; this is a measured tradeoff, not a further memory
improvement. It remains below 1 GB in the final observation. The unchanged
opportunity phase also varied, so the total-time change cannot be attributed
entirely to this migration. These are individual local observations, not speed
or memory guarantees.

The final same-session six-asset pair takes 6.25 -> 4.89 seconds overall and
3.29 -> 2.01 seconds for scheduling, with exact whole-report equality. Its report
occupies 16,722,768 -> 15,934,424 bytes of reachable heap terms before crossing
the verification worker boundary. Shared term size is not encoded disk size or
peak RSS. The snapshot includes the same models, constraints and work ceilings
for both variants.

A memory profile localized the intermediate regression to final path processing;
therefore output projection alone was insufficient. Tail-called ownership scopes
and the horizon continuation avoid retaining older cache versions across the
asset loop and subsequent resource replay. No extra physics evaluations, skipped
checks, lower resolution or forced production collection were introduced.

## Validation

Focused native/path/resource/explanation tests: **77 passed**. New tests cover
native structs/tuples/atoms, output projection, malformed and modified callback
results, explicit unknown margins, bounded data, ambiguous fields, opaque terms,
reserved completed-output markers, native resource state and native failure
explanations. A traced actual path evaluation confirms **zero calls** to JSON
normalization after preparation. Final fast suite: **5,490 passed / 1,148
excluded**, 241.8 seconds. Formatting and whitespace checks pass.

[Durable observations](native_results_observation.json) record complete report
identity, controls, work counts, phase probes and final source hashes. Raw local
artifacts are under ignored `tmp/native_results_*` directories. Historical
maturity acceptance is unchanged; changes remain uncommitted.

## Validation policy follow-up

Native types reduce the need for generic representation validation. External
inputs still need thorough admission; fresh callback results need domain-contract
checks, and admitted internal values should be reused directly. JSON-specific
compatibility belongs at output. The current NativeData callback guard is
intentionally conservative: it still checks bounded collections, UTF-8 text and
supported diagnostic data recursively. Those generic payload checks are candidates
for deferral to report projection, separate from required finite-number, outcome,
identity, unit and frame invariants. Struct tags alone do not enforce those
invariants, but they are also not a reason to repeat full recursive validation
between internal layers. Model-owned constructors/contracts can establish them
once, backed by focused tests and boundary admission.
