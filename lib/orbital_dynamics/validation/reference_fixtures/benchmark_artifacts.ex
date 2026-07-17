defmodule OrbitalDynamics.Validation.ReferenceFixtures.BenchmarkArtifacts do
  @moduledoc false

  @fixtures %{
    "fixture.artifact.study_benchmark.v1" => %{
      "id" => "fixture.artifact.study_benchmark.v1",
      "model_id" => "artifact.study_benchmark.v1",
      "reference_case" => "checked-in persisted study benchmark artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/study_benchmark.json",
        "contract" => "study_benchmark.v1"
      },
      "expected" => %{
        "schema_version" => 1,
        "benchmark_mode_count" => 1,
        "repetition_count" => 2,
        "result_count" => 2,
        "local_result_count" => 2,
        "matches_baseline_count" => 2,
        "failure_count_total" => 0,
        "scenario_count_total" => 8,
        "trajectory_count_total" => 8,
        "manifest_path" => "studies/raise_apogee_search.json",
        "manifest_sha256_length" => 64,
        "max_duration_ms" => 3
      },
      "tolerances" => %{
        "schema_version" => 0,
        "benchmark_mode_count" => 0,
        "repetition_count" => 0,
        "result_count" => 0,
        "local_result_count" => 0,
        "matches_baseline_count" => 0,
        "failure_count_total" => 0,
        "scenario_count_total" => 0,
        "trajectory_count_total" => 0,
        "manifest_sha256_length" => 0,
        "max_duration_ms" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not performance certification",
        "checks persisted benchmark shape, counts, and baseline-match metadata only"
      ]
    },
    "fixture.artifact.study_benchmark.distributed_concurrency_sweep" => %{
      "id" => "fixture.artifact.study_benchmark.distributed_concurrency_sweep",
      "model_id" => "artifact.study_benchmark.v1",
      "reference_case" => "checked-in distributed concurrency sweep benchmark artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/distributed_concurrency_sweep.json",
        "contract" => "study_benchmark.v1"
      },
      "expected" => %{
        "schema_version" => 1,
        "benchmark_mode_count" => 2,
        "repetition_count" => 3,
        "result_count" => 108,
        "local_result_count" => 54,
        "distributed_result_count" => 54,
        "matches_baseline_count" => 108,
        "failure_count_total" => 0,
        "scenario_count_total" => 1_188_000,
        "trajectory_count_total" => 1_188_000,
        "manifest_path" => "studies/leo_dispersion_monte_carlo.json",
        "manifest_sha256_length" => 64,
        "max_duration_ms" => 3_352,
        "backend_count" => 0,
        "propagator_option_count" => 0,
        "monte_carlo_count_option_count" => 2,
        "max_concurrency_option_count" => 3,
        "task_chunk_size_option_count" => 3
      },
      "tolerances" => %{
        "schema_version" => 0,
        "benchmark_mode_count" => 0,
        "repetition_count" => 0,
        "result_count" => 0,
        "local_result_count" => 0,
        "distributed_result_count" => 0,
        "matches_baseline_count" => 0,
        "failure_count_total" => 0,
        "scenario_count_total" => 0,
        "trajectory_count_total" => 0,
        "manifest_sha256_length" => 0,
        "max_duration_ms" => 0,
        "backend_count" => 0,
        "propagator_option_count" => 0,
        "monte_carlo_count_option_count" => 0,
        "max_concurrency_option_count" => 0,
        "task_chunk_size_option_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not performance certification",
        "checks distributed/local benchmark rows, option sweep shape, and baseline-match metadata only"
      ]
    },
    "fixture.artifact.study_benchmark.distributed_chunk_sweep" => %{
      "id" => "fixture.artifact.study_benchmark.distributed_chunk_sweep",
      "model_id" => "artifact.study_benchmark.v1",
      "reference_case" => "checked-in distributed chunk sweep benchmark artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/distributed_chunk_sweep.json",
        "contract" => "study_benchmark.v1"
      },
      "expected" => %{
        "schema_version" => 1,
        "benchmark_mode_count" => 2,
        "repetition_count" => 3,
        "result_count" => 72,
        "local_result_count" => 36,
        "distributed_result_count" => 36,
        "matches_baseline_count" => 72,
        "failure_count_total" => 0,
        "scenario_count_total" => 792_000,
        "manifest_path" => "studies/leo_dispersion_monte_carlo.json",
        "manifest_sha256_length" => 64,
        "max_duration_ms" => 4_000,
        "monte_carlo_count_option_count" => 2,
        "task_chunk_size_option_count" => 6
      },
      "tolerances" => %{
        "schema_version" => 0,
        "benchmark_mode_count" => 0,
        "repetition_count" => 0,
        "result_count" => 0,
        "local_result_count" => 0,
        "distributed_result_count" => 0,
        "matches_baseline_count" => 0,
        "failure_count_total" => 0,
        "scenario_count_total" => 0,
        "manifest_sha256_length" => 0,
        "max_duration_ms" => 0,
        "monte_carlo_count_option_count" => 0,
        "task_chunk_size_option_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not performance certification",
        "checks distributed chunk sweep rows, option shape, and baseline-match metadata only"
      ]
    },
    "fixture.artifact.study_benchmark.distributed_monte_carlo_scaling" => %{
      "id" => "fixture.artifact.study_benchmark.distributed_monte_carlo_scaling",
      "model_id" => "artifact.study_benchmark.v1",
      "reference_case" => "checked-in distributed Monte Carlo scaling benchmark artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/distributed_monte_carlo_scaling.json",
        "contract" => "study_benchmark.v1"
      },
      "expected" => %{
        "schema_version" => 1,
        "benchmark_mode_count" => 2,
        "repetition_count" => 3,
        "result_count" => 18,
        "local_result_count" => 9,
        "distributed_result_count" => 9,
        "matches_baseline_count" => 18,
        "failure_count_total" => 0,
        "scenario_count_total" => 133_200,
        "trajectory_count_total" => 133_200,
        "manifest_path" => "studies/leo_dispersion_monte_carlo.json",
        "manifest_sha256_length" => 64,
        "max_duration_ms" => 3_289,
        "backend_count" => 0,
        "propagator_option_count" => 0,
        "monte_carlo_count_option_count" => 3,
        "max_concurrency_option_count" => 0,
        "task_chunk_size_option_count" => 0
      },
      "tolerances" => %{
        "schema_version" => 0,
        "benchmark_mode_count" => 0,
        "repetition_count" => 0,
        "result_count" => 0,
        "local_result_count" => 0,
        "distributed_result_count" => 0,
        "matches_baseline_count" => 0,
        "failure_count_total" => 0,
        "scenario_count_total" => 0,
        "trajectory_count_total" => 0,
        "manifest_sha256_length" => 0,
        "max_duration_ms" => 0,
        "backend_count" => 0,
        "propagator_option_count" => 0,
        "monte_carlo_count_option_count" => 0,
        "max_concurrency_option_count" => 0,
        "task_chunk_size_option_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not performance certification",
        "checks distributed/local Monte Carlo benchmark rows, option sweep shape, and baseline-match metadata only"
      ]
    },
    "fixture.artifact.study_benchmark.distributed_diagnostic_sweep" => %{
      "id" => "fixture.artifact.study_benchmark.distributed_diagnostic_sweep",
      "model_id" => "artifact.study_benchmark.v1",
      "reference_case" => "checked-in distributed diagnostic sweep benchmark artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/distributed_diagnostic_sweep.json",
        "contract" => "study_benchmark.v1"
      },
      "expected" => %{
        "schema_version" => 1,
        "benchmark_mode_count" => 2,
        "repetition_count" => 3,
        "result_count" => 36,
        "local_result_count" => 12,
        "distributed_result_count" => 24,
        "matches_baseline_count" => 36,
        "failure_count_total" => 0,
        "scenario_count_total" => 396_000,
        "manifest_path" => "studies/leo_dispersion_monte_carlo.json",
        "manifest_sha256_length" => 64,
        "max_duration_ms" => 2_074,
        "monte_carlo_count_option_count" => 2,
        "max_concurrency_option_count" => 2,
        "task_chunk_size_option_count" => 2
      },
      "tolerances" => %{
        "schema_version" => 0,
        "benchmark_mode_count" => 0,
        "repetition_count" => 0,
        "result_count" => 0,
        "local_result_count" => 0,
        "distributed_result_count" => 0,
        "matches_baseline_count" => 0,
        "failure_count_total" => 0,
        "scenario_count_total" => 0,
        "manifest_sha256_length" => 0,
        "max_duration_ms" => 0,
        "monte_carlo_count_option_count" => 0,
        "max_concurrency_option_count" => 0,
        "task_chunk_size_option_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not performance certification",
        "checks distributed diagnostic sweep rows, option shape, and baseline-match metadata only"
      ]
    },
    "fixture.artifact.study_benchmark.distributed_monte_carlo_chunked" => %{
      "id" => "fixture.artifact.study_benchmark.distributed_monte_carlo_chunked",
      "model_id" => "artifact.study_benchmark.v1",
      "reference_case" => "checked-in distributed Monte Carlo chunked benchmark artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/distributed_monte_carlo_chunked.json",
        "contract" => "study_benchmark.v1"
      },
      "expected" => %{
        "schema_version" => 1,
        "benchmark_mode_count" => 2,
        "repetition_count" => 3,
        "result_count" => 18,
        "local_result_count" => 9,
        "distributed_result_count" => 9,
        "matches_baseline_count" => 18,
        "failure_count_total" => 0,
        "scenario_count_total" => 133_200,
        "manifest_path" => "studies/leo_dispersion_monte_carlo.json",
        "manifest_sha256_length" => 64,
        "max_duration_ms" => 2_241,
        "monte_carlo_count_option_count" => 3
      },
      "tolerances" => %{
        "schema_version" => 0,
        "benchmark_mode_count" => 0,
        "repetition_count" => 0,
        "result_count" => 0,
        "local_result_count" => 0,
        "distributed_result_count" => 0,
        "matches_baseline_count" => 0,
        "failure_count_total" => 0,
        "scenario_count_total" => 0,
        "manifest_sha256_length" => 0,
        "max_duration_ms" => 0,
        "monte_carlo_count_option_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not performance certification",
        "checks distributed Monte Carlo chunked rows, option shape, and baseline-match metadata only"
      ]
    },
    "fixture.artifact.study_benchmark.monte_carlo_scaling" => %{
      "id" => "fixture.artifact.study_benchmark.monte_carlo_scaling",
      "model_id" => "artifact.study_benchmark.v1",
      "reference_case" => "checked-in local Monte Carlo scaling benchmark artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/monte_carlo_scaling.json",
        "contract" => "study_benchmark.v1"
      },
      "expected" => %{
        "schema_version" => 1,
        "benchmark_mode_count" => 1,
        "repetition_count" => 1,
        "result_count" => 2,
        "local_result_count" => 2,
        "distributed_result_count" => 0,
        "matches_baseline_count" => 2,
        "failure_count_total" => 0,
        "scenario_count_total" => 220,
        "manifest_path" => "studies/leo_dispersion_monte_carlo.json",
        "manifest_sha256_length" => 64,
        "max_duration_ms" => 16,
        "monte_carlo_count_option_count" => 2
      },
      "tolerances" => %{
        "schema_version" => 0,
        "benchmark_mode_count" => 0,
        "repetition_count" => 0,
        "result_count" => 0,
        "local_result_count" => 0,
        "distributed_result_count" => 0,
        "matches_baseline_count" => 0,
        "failure_count_total" => 0,
        "scenario_count_total" => 0,
        "manifest_sha256_length" => 0,
        "max_duration_ms" => 0,
        "monte_carlo_count_option_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not performance certification",
        "checks local Monte Carlo scaling rows, option shape, and baseline-match metadata only"
      ]
    },
    "fixture.artifact.study_benchmark.nx_study_benchmark" => %{
      "id" => "fixture.artifact.study_benchmark.nx_study_benchmark",
      "model_id" => "artifact.study_benchmark.v1",
      "reference_case" => "checked-in Nx study benchmark artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/nx_study_benchmark.json",
        "contract" => "study_benchmark.v1"
      },
      "expected" => %{
        "schema_version" => 1,
        "benchmark_mode_count" => 1,
        "repetition_count" => 2,
        "result_count" => 12,
        "local_result_count" => 12,
        "distributed_result_count" => 0,
        "matches_baseline_count" => 12,
        "failure_count_total" => 0,
        "scenario_count_total" => 13_200,
        "trajectory_count_total" => 13_200,
        "manifest_path" => "studies/leo_dispersion_monte_carlo.json",
        "manifest_sha256_length" => 64,
        "max_duration_ms" => 67_760,
        "backend_count" => 3,
        "propagator_option_count" => 3,
        "monte_carlo_count_option_count" => 2,
        "max_concurrency_option_count" => 0,
        "task_chunk_size_option_count" => 0
      },
      "tolerances" => %{
        "schema_version" => 0,
        "benchmark_mode_count" => 0,
        "repetition_count" => 0,
        "result_count" => 0,
        "local_result_count" => 0,
        "distributed_result_count" => 0,
        "matches_baseline_count" => 0,
        "failure_count_total" => 0,
        "scenario_count_total" => 0,
        "trajectory_count_total" => 0,
        "manifest_sha256_length" => 0,
        "max_duration_ms" => 0,
        "backend_count" => 0,
        "propagator_option_count" => 0,
        "monte_carlo_count_option_count" => 0,
        "max_concurrency_option_count" => 0,
        "task_chunk_size_option_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not performance certification",
        "checks Nx benchmark backend coverage, option shape, and baseline-match metadata only"
      ]
    }
  }

  def all, do: @fixtures
end
