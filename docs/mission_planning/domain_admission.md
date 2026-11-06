# Domain admission and deferred diagnostic validation

Fresh path/resource callbacks now receive focused domain admission. The runner
checks result/container shape, a proper nonempty list of at most 2,048 native
checks, unique identifiers, valid outcomes, finite bounded margins and paired
units. Identifiers are valid text of 1–256 bytes; unit labels remain valid text
of 1–64 bytes. Diagnostic details cannot replace domain fields. Existing state,
pointing and frame checks in the physical models/runners remain unchanged.

Admission does not recursively traverse metrics, descriptive check details or
resource state to check serialization depth, node counts, text bytes or UTF-8.
Resource-state admission checks map/struct shape; the resource model owns its
state-domain invariants. A custom model must validate fields it uses in physical
calculations, just as it owns its equations and units. The generic framework does
not infer the meaning or required bounds of arbitrary diagnostic metrics.

The internal computational caches retain admitted native objects directly.
`Result.new!/2` remains an eager **domain** constructor, not a guarantee that all
of its optional diagnostic payload can be exported. Struct construction alone
still does not establish domain validity, so modified/forged outcomes and margins
are rejected at admission.

## Output boundaries

Raw callback metrics and captured resource state enter report evidence through
`ReportData.Pending`. This wrapper records a reference and label, without scanning
or transforming the payload. When a closed asset partition or public report is
projected, the raw value goes through bounded payload validation, followed by
JSON-value projection. Check details follow the same rule in their explicit
check-report projection. Numeric state comparison runs on native state before
report wrappers are attached; samples retain a separate deferred state reference.

Output rejects invalid text, improper/oversized collections, excessive depth,
unsupported opaque values and ambiguous atom/string report fields. Discarded
optional diagnostics need no serialization validation. Invalid diagnostics that
are actually reported fail report construction; they do not become physical
infeasibility or a supported returned report.

Internal `Pending` and `Completed` wrappers are rejected when found inside a raw
payload. Computational container checks also reject either marker at the root.
Thus a callback cannot smuggle a pre-projected object into metrics/state/details
and bypass the raw export check. Framework-owned completed partitions still
unwrap without rescanning. This uses separate raw-data and owned-output paths,
not a callback-controlled trusted flag or a validation cache.

The numerical controls, work counters, cache keys/lifetime and output schema are
unchanged. Mission `Evaluation`, event metadata and environment preparation are
outside this slice; their remaining normalization paths are unchanged.

## Verification

The actual path-runner trace test now observes both `JsonSafety.normalize_input!/2`
and `NativeData.validate!/2`. After preparation, three real callback evaluations
produce **zero calls** to either recursive function. Domain checks still run.
The same test retains malformed-outcome rejection; additional tests separate
immediate domain errors from deferred diagnostic errors and verify nested marker
rejection at output.

The complete six-spacecraft/nine-request reports before/after match exactly as
Elixir terms, without excluding fields, canonical digest
`5ab2dc035d95e848246f95996fafc833916b39da8c548e82b2e10df86bf2735c`.
Same-session observations: planning 4.89 -> 4.78 seconds; scheduling 1.93 ->
1.85 seconds. Both reports retain 15,934,424 bytes of reachable heap terms.
These are individual observations, not performance thresholds or independent
physical validation.

```sh
# Baseline is the immediately preceding native-result implementation.
MIX_ENV=test mix run dev/verify_native_results.exs tmp/domain_admission_baseline tmp/domain_admission_verify
MIX_ENV=test mix orbital_dynamics.mission.scaling --sizes 100 --requests 25 --output-dir tmp/domain_admission_scale
```

The baseline source snapshot includes earlier uncommitted slices. Durable source
hashes identify the compared modules. Focused native/path/resource/explanation
checks: 79 passed. Large-study and full-suite results are recorded when complete.
Historical maturity acceptance is unchanged.

## Large-study observation

| 100 spacecraft / 25 requests | Before | Focused admission |
| --- | ---: | ---: |
| Total planning seconds | 155.53 | 147.79 |
| Opportunity generation seconds | 128.34 | 122.02 |
| Scheduling seconds | 25.85 | 24.28 |
| Sampled peak VM GB | 0.881 | 1.108 |
| Path evaluations | 613,893 | 613,893 |
| Scheduled requests | 25 | 25 |

Inputs, controls and compact result digest match exactly; all 2,500 opportunity
searches complete under their declared policy, with supported planning/resources.
This is a measured memory tradeoff of about **227 MB**, not a memory reduction.
Deferred payload references add retained objects, but this run did not isolate
their exact contribution to the peak. The unchanged opportunity phase also
varied, so total-time differences cannot be attributed entirely to admission.
These are single local observations on Apple M1 / 16 GB, macOS 15.8,
Elixir 1.20.4 / OTP 29, without warmup. Sampled VM total is not peak RSS.

Moving payload checks does not sandbox callback code or prevent a model from
allocating oversized diagnostics before output. Model-owned contracts and
capture policies remain responsible for sensible diagnostic generation. The
framework's check-list and work/search budgets still bound its computational
loops. Invalid reported diagnostics fail export; discarded diagnostics are not
needlessly scanned.

[Durable observations](domain_admission_observation.json) preserve complete-report
identity, controls, work counts, timing/memory observations and source hashes.
Final fast suite: **5,492 passed / 1,148 excluded**, 258.0 seconds.
Formatting and whitespace checks pass. Commit-time verification confirms the
same source hashes and suite result.
