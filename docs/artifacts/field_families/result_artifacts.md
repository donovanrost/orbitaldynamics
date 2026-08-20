# Result Artifacts

Result artifacts are emitted by `ResultSet.Artifact.build/2` and usually contain
propagation outputs plus run metadata:

- `schema_version`, `study_id`, and `generated_at`
- stable run identity from `run.id`; `mix orbital_dynamics.study.run` accepts
  `--run-id` alongside `--generated-at` for repeatable checked-in artifact
  refreshes, `--format json` for machine-readable generation summaries, and
  `--resume` to reuse a checked result only when it validates as
  `result_artifact.v1`, matches the manifest SHA, and matches the requested
  run ID when one is supplied; the same reusable preflight is exposed as
  `OrbitalDynamics.ResultSet.Artifact.resume_check/2`
- opt-in interrupted local execution through `--checkpoint PATH` followed by
  `--resume-checkpoint PATH`. The separate `study_checkpoint.v1` stores the full
  ordered manifest index/ID identity and completed per-scenario propagation
  outcomes. Its deterministic manifest/study/model/run-option hashes,
  checkpoint-level content hash, and per-entry payload hashes are all validated
  before reuse. Writes use a synced same-directory temporary file plus atomic
  rename, so a failed replacement leaves the prior durable checkpoint usable.
  Resume runs only missing indexes and emits the exact reused/run partition and
  checkpoint path/SHA provenance in the final run and execution report.
  Checkpoint payload decoding uses the Erlang safe-term mode. Output/checkpoint
  aliases, stale/corrupt/duplicate/missing/mismatched rows, distributed task
  supervisors, and batch propagation are rejected. This is between-scenario
  local recovery only: no automatic retry, persistent queue, within-scenario
  checkpoint, distributed recovery, or planner mutation is implied.
- explicit failed-scenario retry through
  `mix orbital_dynamics.study.run --retry-failed-from SOURCE --output NEW`; the
  source must pass the same result-artifact, study-ID, and manifest-SHA
  preflight, failed rows must match the source manifest's scenario IDs and
  zero-based indexes, and selection is canonicalized into manifest order. The
  retry artifact preserves seeds and assumptions, records source path/SHA/run
  provenance, and contains only retry-batch results with their original source
  indexes. It does not merge completed source results or provide checkpoint
  resume. Its execution-report assumptions and model limits identify it as an
  explicit failed-scenario retry batch and state that source results are not
  merged, no persistent queue exists, and failed rows are not retried
  automatically; ordinary reports retain their existing non-resumable defaults.
- `run`, `execution_report`, and `payload_metrics`
- `assumptions`, including backend, provider, validation, and environment model
  declarations. `external_provider_policy` is semantically linted so offline
  artifacts cannot claim hidden network calls, provider counts must be
  non-negative and match provider rows, and explicit provider rows must carry an
  `id` plus a direct or provenance-supplied `trust_boundary`. Environment model
  and provider capability contracts also require that trust boundary whenever
  `network_access` is declared true, and their supported-body, known-limit, and
  provider-output arrays are validated as string arrays.
- schema lint preserves plain result wrappers as `result_artifact.v1` by
  default; only wrappers with embedded `campaign_plan` or `candidate_refresh`
  are unwrapped to the nested product artifact unless `--contract` is supplied.
- trajectory summaries with row-level `propagation_backend`, `force_model`,
  `numerical_method`, `validation_level`, and schema-visible `model_limits`
  copied from the propagated trajectory assumptions
- event outputs such as `access_windows`, `eclipse_intervals`,
  `target_visibility_windows`, and `ground_track_crossings`, with
  row-level `event_detector`, `event_model`, `validation_level`,
  `timing_policy`, interpolation/refinement labels, and schema-visible
  `model_limits` copied from the detector capability metadata. Access,
  target-visibility, and eclipse assumptions also preserve sampled boundary
  labels and bounded interpolation detail so downstream products can
  distinguish clipped sample edges from linearly interpolated boundaries without
  treating them as root-solved event times. Interpolated/refined boundary
  details now include the local sample bracket width and before/after epoch
  seconds, so downstream tooling can use the bracket-local tolerance instead of
  only the trajectory-wide max sample cadence.
- optional product outputs such as `campaign_plan`
- optional search and reproducibility outputs such as
  `monte_carlo_reproducibility_report`

`result_artifact.v1` is the explicit top-level compatibility contract for the
full study result wrapper. Default linting still validates promoted embedded
contracts, while `--contract result_artifact.v1` validates the wrapper fields,
execution report, payload metrics, trajectory summary rows, and typed event rows.
Trajectory summary rows validate `model_limits` against
`ResultSet.Artifact.trajectory_model_limits/1`, keeping the persisted
summary-only, non-flight-certified propagation boundary aligned with the
producer. Event rows validate `model_limits` against
`ResultSet.Artifact.event_detector_model_limits/1`, so access, eclipse,
target-visibility, and ground-track products remain tied to detector
capabilities. Declared `scenario_rankings` now carry the
`ResultSet.Report` reporting model, validation level, source, assumptions, and
`model_limits`, with executable validation checking those limits against
`ResultSet.Report.model_limits/0`. Embedded `constraint_results` now reuse the
same typed constraint-row schema and executable validation as
`constraint_report.v1` rows, so result-artifact constraint status, threshold,
value, score, and operator fields are machine-readable without opening the
summary report. Embedded `maneuver_recommendations` now export the same
typed row shape as standalone `maneuver_recommendation.v1`, including
delta-v vector shape and recommendation model-limit metadata. Embedded
`constraint_report`, `maneuver_review_report`, and
`monte_carlo_reproducibility_report` sections now export their declared nested
contract schemas inside `result_artifact.v1`, and executable result-artifact
validation checks their report-level model-limit metadata at embedded paths.
`ResultSet.Report.compare/2` emits a `ranking_comparison_report.v1` when both
saved artifacts include compatible declared `scenario_rankings`, making ranking
deltas available from concrete result-artifact comparisons. Result-set summary
and ranking helpers accept clean numeric strings for persisted trajectory
metrics, maneuver counts, event boundary times, and declared ranking values
before computing summaries, durations, ranks, and boundary deltas; malformed
numeric strings remain missing quantitative evidence.
`ground_track_crossings` rows are generated from manifest
`ground_track_crossings` requests and carry the request ID, crossing axis,
target degrees, frame, crossing direction, sampled/interpolated timing metadata,
row-level detector capability labels, local boundary timing metadata, and
coordinate-model assumptions.
`EventDetectors.GroundTrackCrossings.refine_crossing_boundary/3` and
`OrbitalDynamics.refine_ground_track_crossing_boundary/3` expose the same
linear margin interpolation for a bracketed sample pair, including frame,
coordinate-model, rotation, root-solved, and sample-cadence confidence
assumptions.
Body-fixed requests can declare constant
rotation-rate, epoch, and angle-offset assumptions; result rows preserve those
values without claiming Earth-orientation-provider fidelity.
Direct study requests can also pass a validated Earth-rotation provider for
body-fixed ground-track calculations; result rows preserve the provider module,
provider capability ID, provider model, rotation rate when supplied, and
before/after rotation angles used by the crossing bracket.
`execution_report.v1` exports deterministic execution-plan metadata and nested
failed-scenario rows so run review tooling can inspect scenario count, task
batches, waves, chunking, adaptive chunk-size recommendation, supervisor
concurrency, scenario IDs, execution stages, and error payloads without
treating the failure list as an untyped array. The standalone
`study_results/execution_report_v1.json` fixture demonstrates a distributed
Monte Carlo run that completed with one isolated propagation timeout and carries
top-level `model_limits` for the non-resumable artifact-summary boundary plus
the same backend-selection and backend-acceptance evidence exposed by generated
study-run result artifacts. Executable validation checks those limits against
`OrbitalDynamics.ResultSet.Artifact.execution_report_model_limits/0`. Its assumptions schema also types the checked-in
failure-isolation purpose, source, resumability label, and acceptance-tier
description so run-review tooling can consume them without parsing opaque
assumption maps. Failed-scenario rows from an execution report can
now be normalized into `execution_review` operator-review rows and
`review_execution` Cadence import gates, while completed reports with no failed
scenarios produce an empty review package. Top-level `result_artifact.v1`
wrappers now use the same public review/import facades before the generic V1
campaign fallback, preserving the result artifact ID and routing embedded
execution failures, constraint report rows, and maneuver review rows to the
same `execution_review`, `constraint_review`, and `maneuver_review`
operator-review and Cadence-import gates.
`result_artifact.v1` executable validation now also recomputes the emitted `result_payload_metrics.v1`
`artifact_body_bytes`, top-level key count, and per-section byte/row counts
against the submitted artifact body, excluding the metrics block itself, so
payload-cost evidence cannot silently drift from regenerated result artifacts.
`monte_carlo_reproducibility_report.v1` exports stable generated-scenario ID
arrays, capability-exact known-limit and `model_limits` arrays, and three-number
position/velocity sigma vectors for seeded dispersion review. The standalone
`monte_carlo_reproducibility_report_v1.json` fixture keeps that reproducibility
surface lintable outside the larger Monte Carlo result artifact. Executable
validation treats the seed plus requested/generated scenario counts as integers
and checks both `known_limits` and `model_limits` against
`OrbitalDynamics.Search.MonteCarlo.capabilities/0`; the exported JSON Schema now
exposes the same typed reproducibility-report shape when embedded in a full
`result_artifact.v1`, including generated-scenario IDs, sigma triplets, and
capability-exact `model_limits`, and matches the string-valued source
provenance used by generated reports.
`study_benchmark.v1` is the executable contract for persisted benchmark histories
such as `study_benchmark.json`, distributed scaling sweeps, and Nx benchmark
artifacts. Schema lint now validates benchmark manifests, row identity, timing
fields, baseline-match flags, failure counts, and per-node trajectory counts
instead of skipping those performance-evidence files during `--all` runs.
Newly produced benchmark artifacts emit top-level `model_limits` from
`Study.Benchmark.Report.model_limits/0`, and schema validation checks the exact
same set when the field is present, keeping persisted histories tied to the
artifact-level median-summary boundary. `Study.Benchmark.Report.trend_summary/2`
compares multiple generated benchmark artifacts by matching benchmark groups
and ordering points by artifact `generated_at`, reporting median-runtime deltas
as descriptive trend evidence without claiming statistical significance.
`OperationalScale.compare_benchmark_trend/2` can evaluate that trend summary
against V1/V2/V3 scale targets while keeping latest scale-target violations
separate from descriptive runtime regressions; the multi-artifact benchmark
report attaches that aggregate comparison when `--scale-target` is supplied.
Newly generated study-benchmark rows also carry result-artifact payload cost
evidence (`artifact_body_bytes`, `artifact_size_mb`,
`artifact_bytes_per_scenario`, and `payload_top_level_key_count`) plus the
run execution plan and scalar batch/wave fields (`task_batch_count`,
`batches_per_wave`, `wave_count`, `effective_task_chunk_size`, and
`supervisor_count`). The study benchmark report summarizes payload cost,
task-batch count, and wave count as medians alongside runtime, overhead,
speedup, and node-balance evidence.
The persisted propagator benchmark summary helper also accepts clean numeric
strings for scenario counts, sample counts, failure counts, elapsed timings, and
sample-rate metadata before computing median runtime and speedup groups.
`manifest_field_reference.v1` validates the generated study-manifest reference
artifact used by docs and import-gate automation. The artifact keeps
`schema_contract: study_manifest.v1` to identify the schema it describes, while
schema lint infers the reference contract from `reference_mode` and checks field
paths, parent paths, top-level sections, array-item flags, required flags,
supported values, object-level required-child lists, `anyOf` required
alternatives, embedded artifact `schema_contract_ref` values, nested-contract
lists, numeric map `additional_properties_type` hints, stable public-ID
patterns for ID-like fields, trust-boundary source hints for imported state
rows that accept either direct `trust_boundary` or `provenance.trust_boundary`,
numeric bounds, field-count consistency, duplicate-path rejection, parent-path
integrity, top-level required-field consistency, activation-section consistency,
supported output/propagator/objective vocabulary consistency with the schema
enum rows, a schema-visible `supported` object shape for external validators,
section consistency, array-item marker consistency, and the minimum row-routing
fields (`path`, `parent_path`, `section`, `type`, `required`, and `array_item`)
that CLI docs and import gates need to treat the reference as structured data.
It also carries a compact
`identity_policy` summary with stable-ID pattern, semantic generated-ID
invariants, and the campaign/candidate-refresh/contact-contention generated
ID scopes so manifest preflight tooling can inspect public-identity rules
without loading the full schema bundle.
