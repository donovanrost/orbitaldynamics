defmodule OrbitalDynamics.Validation.BenchmarkFixtureTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{Schema, Validation}

  import OrbitalDynamics.Validation.BenchmarkFixtures,
    only: [
      distributed_chunk_benchmark_fixture: 0,
      distributed_chunk_benchmark_fixture_observations: 0,
      distributed_concurrency_benchmark_fixture: 0,
      distributed_concurrency_benchmark_fixture_observations: 0,
      distributed_diagnostic_benchmark_fixture: 0,
      distributed_diagnostic_benchmark_fixture_observations: 0,
      distributed_monte_carlo_chunked_benchmark_fixture: 0,
      distributed_monte_carlo_chunked_benchmark_fixture_observations: 0,
      distributed_monte_carlo_scaling_benchmark_fixture: 0,
      distributed_monte_carlo_scaling_benchmark_fixture_observations: 0,
      monte_carlo_scaling_benchmark_fixture: 0,
      monte_carlo_scaling_benchmark_fixture_observations: 0,
      nx_study_benchmark_fixture: 0,
      nx_study_benchmark_fixture_observations: 0,
      study_benchmark_fixture: 0,
      study_benchmark_fixture_observations: 0
    ]

  test "verifies curated study benchmark reference fixtures" do
    fixtures = [
      {
        "fixture.artifact.study_benchmark.v1",
        study_benchmark_fixture(),
        study_benchmark_fixture_observations(),
        "matches_baseline_count",
        1
      },
      {
        "fixture.artifact.study_benchmark.distributed_concurrency_sweep",
        distributed_concurrency_benchmark_fixture(),
        distributed_concurrency_benchmark_fixture_observations(),
        "distributed_result_count",
        53
      },
      {
        "fixture.artifact.study_benchmark.distributed_chunk_sweep",
        distributed_chunk_benchmark_fixture(),
        distributed_chunk_benchmark_fixture_observations(),
        "task_chunk_size_option_count",
        5
      },
      {
        "fixture.artifact.study_benchmark.distributed_monte_carlo_scaling",
        distributed_monte_carlo_scaling_benchmark_fixture(),
        distributed_monte_carlo_scaling_benchmark_fixture_observations(),
        "monte_carlo_count_option_count",
        2
      },
      {
        "fixture.artifact.study_benchmark.distributed_diagnostic_sweep",
        distributed_diagnostic_benchmark_fixture(),
        distributed_diagnostic_benchmark_fixture_observations(),
        "distributed_result_count",
        23
      },
      {
        "fixture.artifact.study_benchmark.distributed_monte_carlo_chunked",
        distributed_monte_carlo_chunked_benchmark_fixture(),
        distributed_monte_carlo_chunked_benchmark_fixture_observations(),
        "result_count",
        17
      },
      {
        "fixture.artifact.study_benchmark.monte_carlo_scaling",
        monte_carlo_scaling_benchmark_fixture(),
        monte_carlo_scaling_benchmark_fixture_observations(),
        "repetition_count",
        2
      },
      {
        "fixture.artifact.study_benchmark.nx_study_benchmark",
        nx_study_benchmark_fixture(),
        nx_study_benchmark_fixture_observations(),
        "backend_count",
        2
      }
    ]

    for {fixture_id, artifact, observations, stale_field, stale_value} <- fixtures do
      assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

      assert fixture["model_id"] == "artifact.study_benchmark.v1"
      assert fixture["fixture_type"] == "curated_internal_artifact_regression"

      assert {:ok, verification} =
               Validation.verify_reference_fixture(fixture_id, observations)

      assert verification["status"] == "pass"
      assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

      stale_observations = Map.put(observations, stale_field, stale_value)

      assert {:ok, stale_verification} =
               Validation.verify_reference_fixture(fixture_id, stale_observations)

      assert stale_verification["status"] == "fail"

      assert Enum.any?(
               stale_verification["checks"],
               &(&1["field"] == stale_field and &1["status"] == "fail")
             )

      assert OrbitalDynamics.validation_artifact_observations("study_benchmark.v1", artifact) ==
               Validation.artifact_observations("study_benchmark.v1", artifact)
    end

    benchmark_report = study_benchmark_fixture()

    assert {:ok, _validated_report} =
             Schema.validate_artifact(benchmark_report, schema_contract: "study_benchmark.v1")

    stale_scenario_count =
      put_in(benchmark_report, ["results", Access.at(0), "scenario_count"], 99)

    assert {:error, stale_scenario_count_report} =
             Schema.validate_artifact(stale_scenario_count,
               schema_contract: "study_benchmark.v1"
             )

    assert Enum.any?(
             stale_scenario_count_report["errors"],
             &(&1["path"] == "$.results[0].scenario_count")
           )
  end
end
