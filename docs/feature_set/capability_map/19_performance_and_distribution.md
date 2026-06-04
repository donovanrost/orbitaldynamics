# 19. Performance and Distribution

Status: **implemented** (with **partial**, **near-term**, **later**, and **out of scope** items noted below).

## Execution engine

- Local concurrency through `ScenarioRunner`.
- Distributed BEAM task supervisors.
- Explicit and deterministic `:auto` task chunking.
- Batch propagation.
- Nx/EXLA backends.
- Benchmark commands and artifacts.
- Runtime telemetry in artifacts.

## Result payload metrics

- Result artifacts emit `result_payload_metrics.v1` byte and row-count summaries by top-level section.
- Executable validation recomputes artifact-body, top-level-key, and per-section byte/row-count evidence against the actual submitted `result_artifact.v1` body.

## Execution report (`execution_report.v1`)

`execution_report.v1` run review summaries carry:

- Execution mode.
- Task settings.
- Execution-plan metadata for scenario count, task batches, waves, chunking, adaptive chunk-size recommendation, supervisor concurrency, phase timings, and node distribution.
- Failed scenario rows with zero-based source `scenario_index`, manual-rerun resumability, and retry recommendations.
- Top-level `model_limits` for the non-resumable artifact-summary boundary, with executable validation against `OrbitalDynamics.ResultSet.Artifact.execution_report_model_limits/0`.
- Explicit external-provider policy metadata declaring whether the run was offline-only or had configured provider boundaries.

### Standalone fixture

A checked-in standalone `execution_report.v1` fixture now demonstrates a distributed Monte Carlo run that completed with:

- One isolated propagation failure row.
- Source scenario index.
- Manual rerun guidance.
- Non-resumable execution `model_limits`.
- Backend-acceptance evidence.

### Operator review routing

- Failed execution reports now normalize into `execution_review` operator-review rows and typed `review_execution` Cadence import gates carrying the same scenario-index and retry guidance.
- Completed execution reports stay out of the review queue.

## Backend selection and acceptance

- Study run assumptions and metadata include `backend_selection_policy`, which labels scalar Elixir as the reference default and Nx/EXLA-style batch backends as experimental accelerators.
- It embeds the selected implementation's backend-acceptance evidence, including reference-match and benchmark-artifact gates before speedup claims.
- `result_artifact.v1` and `execution_report.v1` JSON Schemas expose those nested evidence fields under `assumptions`, including execution failure-isolation purpose/source/resumability fields and backend acceptance-tier descriptions from the checked-in execution fixture.
- Each study-benchmark summary group carries backend-acceptance evidence from `backend_acceptance_policy.v1` so accelerator speedup claims remain tied to reference-output matches and benchmark artifacts.

## Operational scale (`OperationalScale`)

- `OperationalScale` defines executable V1/V2/V3 scale targets for spacecraft count, horizon, candidate windows, scenario count, local runtime, artifact size, replanning cadence, and distributed-execution thresholds.
- Benchmark report summaries can attach operational-scale comparisons with scenario count, local-runtime, distributed-threshold guidance, and distributed node-balance ratios through `--scale-target`.
- `OperationalScale.compare_result_artifact/2` compares completed result artifacts against scale targets using `execution_report.v1` and `result_payload_metrics.v1` evidence for scenario count, local runtime when applicable, artifact size, source run metadata, and distribution-threshold guidance.
- `OperationalScale.compare_benchmark_trend/2` can also evaluate benchmark trend summaries, separating latest scale-target violations from descriptive median-runtime regressions.

## Study benchmarks (`study_benchmark.v1`)

- `study_benchmark.v1` validates persisted benchmark artifacts, including manifest metadata, row identity, timings, baseline-match flags, failure counts, per-node trajectory counts, and exact top-level `model_limits` when present.
- Newly produced benchmark artifacts emit those limits from `Study.Benchmark.Report.model_limits/0`.
- Persisted propagator benchmark summaries normalize clean numeric-string scenario/sample/failure counts, elapsed timings, and sample-rate metadata before median speedup calculations.

### Per-run payload and plan evidence

- Newly generated study-benchmark rows now lift result-payload evidence into per-run `artifact_body_bytes`, `artifact_size_mb`, `artifact_bytes_per_scenario`, and `payload_top_level_key_count` fields.
- Study-benchmark rows now also preserve the run execution plan and scalar batch/wave fields (`task_batch_count`, `batches_per_wave`, `wave_count`, `effective_task_chunk_size`, and `supervisor_count`) so benchmark artifacts explain the chunking and distribution shape used for each run.
- Benchmark summaries report median artifact size, per-scenario payload cost, task-batch count, and wave count next to runtime and node-balance evidence.

### Trend reporting

- Study benchmark reports can now summarize trends across multiple generated benchmark artifacts by matching benchmark groups, ordering them by artifact `generated_at`, and reporting improved/regressed/unchanged median runtime deltas without claiming statistical significance.
- The same multi-artifact trend view is exposed by `mix orbital_dynamics.study.benchmark.report`, including machine-readable `--format json` output for single-artifact and trend summaries.
- The multi-artifact benchmark report attaches the aggregate `OperationalScale.compare_benchmark_trend/2` comparison in text and JSON output when `--scale-target` is supplied.

## Status: partial

- No resumable long-running studies.
- Adaptive chunking is a deterministic V1 recommendation/execution policy for task-supervisor runs, not a feedback loop from historical benchmark telemetry.
- Transfer overhead, payload costs, and failure-isolation rows are now visible in artifacts and can be compared against scale targets, but are not yet modeled by the planner.
- Nx remains experimental evidence, not a default performance win.

## Status: near-term

- Keep failure-isolation examples aligned with resumability work.
- Expand benchmark trend tracking across checked-in large Monte Carlo histories.

## Status: later

- Resumable execution, persistent queues, adaptive distribution, native kernel pools, service backends, and hardware-aware scheduling.

## Status: out of scope

- Making every numerical kernel run on the BEAM.

## Operational scale targets

Operational scale targets are stated per maturity level through `OrbitalDynamics.OperationalScale`:

- spacecraft count supported by a fixed-horizon campaign plan,
- planning horizon and output cadence,
- expected candidate window count,
- Monte Carlo/scenario count,
- acceptable local runtime,
- artifact size limits,
- replanning cadence,
- threshold where distributed execution should outperform local concurrency.

The exact numbers can evolve, but the project needs targets so performance work
does not become abstract.
