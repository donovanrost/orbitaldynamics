defmodule OrbitalDynamics.Study.BenchmarkTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Study.Benchmark
  alias OrbitalDynamics.Study.Benchmark.Report

  test "benchmarks local study execution from a manifest" do
    path = write_manifest!("study_benchmark_local.json")
    on_exit(fn -> File.rm(path) end)

    assert {:ok, artifact} = Benchmark.run(path, modes: ["local"], repetitions: 2)

    assert artifact.manifest.path == path
    assert artifact.model_limits == Report.model_limits()
    assert artifact.benchmark_options.modes == ["local"]
    assert length(artifact.results) == 2
    assert Enum.all?(artifact.results, &(&1.mode == "local"))
    assert Enum.all?(artifact.results, &(&1.matches_baseline == true))
    assert Enum.all?(artifact.results, &(&1.failure_count == 0))
    assert Enum.all?(artifact.results, &is_integer(&1.propagation_ms))
    assert Enum.all?(artifact.results, &is_integer(&1.event_detection_ms))
    assert Enum.all?(artifact.results, &is_integer(&1.artifact_build_ms))
    assert Enum.all?(artifact.results, &is_integer(&1.overhead_ms))
    assert Enum.all?(artifact.results, &is_integer(&1.artifact_body_bytes))
    assert Enum.all?(artifact.results, &(&1.artifact_body_bytes > 0))
    assert Enum.all?(artifact.results, &(&1.artifact_size_mb > 0.0))
    assert Enum.all?(artifact.results, &(&1.artifact_bytes_per_scenario > 0.0))
    assert Enum.all?(artifact.results, &is_integer(&1.payload_top_level_key_count))
    assert Enum.all?(artifact.results, &is_map(&1.execution_plan))
    assert Enum.all?(artifact.results, &is_integer(&1.task_batch_count))
    assert Enum.all?(artifact.results, &is_integer(&1.wave_count))
    assert Enum.all?(artifact.results, &(&1.output_signature.ranking == ["raise_apogee_1_2"]))

    summary =
      artifact
      |> json_safe()
      |> Report.summarize()

    assert [
             %{
               mode: "local",
               repetitions: 2,
               output_matches_baseline: true,
               median_artifact_body_bytes: artifact_body_bytes,
               median_artifact_size_mb: artifact_size_mb,
               median_artifact_bytes_per_scenario: artifact_bytes_per_scenario,
               median_task_batch_count: task_batch_count,
               median_wave_count: wave_count
             }
           ] = summary.groups

    assert artifact_body_bytes > 0.0
    assert artifact_size_mb > 0.0
    assert artifact_bytes_per_scenario > 0.0
    assert task_batch_count > 0.0
    assert wave_count > 0.0
  end

  test "benchmarks monte carlo count variants" do
    path = write_manifest!("study_benchmark_monte_carlo.json", monte_carlo_manifest())
    on_exit(fn -> File.rm(path) end)

    assert {:ok, artifact} =
             Benchmark.run(path,
               modes: ["local"],
               repetitions: 1,
               monte_carlo_counts: [2, 3]
             )

    assert artifact.benchmark_options.monte_carlo_counts == [2, 3]
    assert Enum.map(artifact.results, & &1.monte_carlo_count) == [2, 3]
    assert Enum.map(artifact.results, & &1.scenario_count) == [2, 3]
    assert Enum.all?(artifact.results, &(&1.matches_baseline == true))

    summary =
      artifact
      |> json_safe()
      |> Report.summarize()

    assert [
             %{mode: "local", monte_carlo_count: 2, scenario_count: 2.0},
             %{mode: "local", monte_carlo_count: 3, scenario_count: 3.0}
           ] = summary.groups
  end

  test "records task chunk size benchmark option" do
    path = write_manifest!("study_benchmark_chunked_monte_carlo.json", monte_carlo_manifest())
    on_exit(fn -> File.rm(path) end)

    assert {:ok, artifact} =
             Benchmark.run(path,
               modes: ["local"],
               repetitions: 1,
               monte_carlo_counts: [2],
               task_chunk_size: 2
             )

    assert artifact.benchmark_options.task_chunk_size == 2
    assert [row] = artifact.results
    assert row.scenario_count == 2
    refute Map.has_key?(row, :task_chunk_size)
    assert is_map(row.runtime_telemetry)
  end

  test "local benchmarks ignore task chunk size variants" do
    path =
      write_manifest!(
        "study_benchmark_task_chunk_variants_monte_carlo.json",
        monte_carlo_manifest()
      )

    on_exit(fn -> File.rm(path) end)

    assert {:ok, artifact} =
             Benchmark.run(path,
               modes: ["local"],
               repetitions: 1,
               monte_carlo_counts: [2],
               task_chunk_sizes: [1, 2]
             )

    assert artifact.benchmark_options.task_chunk_sizes == [1, 2]
    assert [row] = artifact.results
    assert row.scenario_count == 2
    refute Map.has_key?(row, :task_chunk_size)
    assert Enum.all?(artifact.results, &(&1.matches_baseline == true))

    summary =
      artifact
      |> json_safe()
      |> Report.summarize()

    assert [
             %{mode: "local", monte_carlo_count: 2, task_chunk_size: nil}
           ] = summary.groups
  end

  test "benchmarks max concurrency variants" do
    path =
      write_manifest!(
        "study_benchmark_max_concurrency_variants_monte_carlo.json",
        monte_carlo_manifest()
      )

    on_exit(fn -> File.rm(path) end)

    assert {:ok, artifact} =
             Benchmark.run(path,
               modes: ["local"],
               repetitions: 1,
               monte_carlo_counts: [2],
               max_concurrencies: [1, 2]
             )

    assert artifact.benchmark_options.max_concurrencies == [1, 2]
    assert Enum.map(artifact.results, & &1.max_concurrency) == [1, 2]
    assert Enum.map(artifact.results, & &1.effective_task_concurrency) == [1, 2]
    assert Enum.all?(artifact.results, &is_map(&1.runtime_telemetry))
    assert Enum.all?(artifact.results, &(&1.matches_baseline == true))

    summary =
      artifact
      |> json_safe()
      |> Report.summarize()

    assert [
             %{mode: "local", monte_carlo_count: 2, max_concurrency: 1},
             %{mode: "local", monte_carlo_count: 2, max_concurrency: 2}
           ] = summary.groups
  end

  test "benchmarks propagator variants" do
    path =
      write_manifest!(
        "study_benchmark_propagator_variants_monte_carlo.json",
        monte_carlo_manifest()
      )

    on_exit(fn -> File.rm(path) end)

    assert {:ok, artifact} =
             Benchmark.run(path,
               modes: ["local"],
               repetitions: 1,
               monte_carlo_counts: [2],
               propagators: ["two_body", "two_body_nx_compiled"]
             )

    assert artifact.benchmark_options.propagators == ["two_body", "two_body_nx_compiled"]
    assert Enum.map(artifact.results, & &1.propagator) == ["two_body", "two_body_nx_compiled"]
    assert Enum.map(artifact.results, & &1.batch_propagation) == [false, true]
    assert Enum.all?(artifact.results, &(&1.matches_baseline == true))

    summary =
      artifact
      |> json_safe()
      |> Report.summarize()

    assert [
             %{mode: "local", propagator: "two_body", monte_carlo_count: 2},
             %{mode: "local", propagator: "two_body_nx_compiled", monte_carlo_count: 2}
           ] = summary.groups
  end

  test "rejects invalid propagator variants clearly" do
    path = write_manifest!("study_benchmark_bad_propagator_variant.json", monte_carlo_manifest())
    on_exit(fn -> File.rm(path) end)

    assert {:error, {:invalid_propagator_variant, "cowell", {:unsupported_propagator, "cowell"}}} =
             Benchmark.run(path,
               modes: ["local"],
               propagators: ["cowell"]
             )
  end

  test "remote mode fails clearly when the node is not connected" do
    path = write_manifest!("study_benchmark_remote_missing.json")
    on_exit(fn -> File.rm(path) end)

    assert {:error, {:study_run_failed, "remote", {:node_unavailable, :"missing@127.0.0.1"}}} =
             Benchmark.run(path,
               modes: ["remote"],
               task_supervisor_node: "missing@127.0.0.1"
             )
  end

  test "remote mode requires an explicit task supervisor node" do
    assert {:error, {:missing_option, :task_supervisor_node}} =
             Benchmark.run("missing.json", modes: ["remote"])
  end

  test "distributed mode requires an explicit task supervisor node" do
    assert {:error, {:missing_option, :task_supervisor_node}} =
             Benchmark.run("missing.json", modes: ["distributed"])
  end

  test "rejects invalid task chunk size" do
    assert {:error, {:invalid_option, :task_chunk_size}} =
             Benchmark.run("missing.json", modes: ["local"], task_chunk_size: 0)
  end

  test "rejects invalid task chunk size variants" do
    assert {:error, {:invalid_option, :task_chunk_sizes}} =
             Benchmark.run("missing.json", modes: ["local"], task_chunk_sizes: [1, 0])

    assert {:error, {:conflicting_options, [:task_chunk_size, :task_chunk_sizes]}} =
             Benchmark.run("missing.json",
               modes: ["local"],
               task_chunk_size: 1,
               task_chunk_sizes: [1]
             )
  end

  test "rejects invalid max concurrency variants" do
    assert {:error, {:invalid_option, :max_concurrency}} =
             Benchmark.run("missing.json", modes: ["local"], max_concurrency: 0)

    assert {:error, {:invalid_option, :max_concurrencies}} =
             Benchmark.run("missing.json", modes: ["local"], max_concurrencies: [1, 0])

    assert {:error, {:conflicting_options, [:max_concurrency, :max_concurrencies]}} =
             Benchmark.run("missing.json",
               modes: ["local"],
               max_concurrency: 1,
               max_concurrencies: [1]
             )
  end

  defp write_manifest!(filename, manifest \\ manifest()) do
    path = Path.join(System.tmp_dir!(), filename)
    File.write!(path, :json.encode(manifest) |> IO.iodata_to_binary())
    path
  end

  defp manifest do
    %{
      "schema_version" => 1,
      "study_id" => "study_benchmark",
      "central_body" => "earth",
      "propagator" => "two_body",
      "propagator_opts" => %{"max_step_s" => 10.0},
      "outputs" => ["trajectories"],
      "constraints" => [
        %{
          "id" => "delta_v_budget",
          "metric" => "total_delta_v_km_s",
          "operator" => "<=",
          "value" => 0.008
        }
      ],
      "search" => %{
        "generator" => "impulsive_burn_grid",
        "id_prefix" => "raise_apogee",
        "objective" => "final_radius_km",
        "rank_limit" => 1,
        "burn_epoch_s" => [55.0],
        "delta_v_km_s" => [[0.0, 0.005, 0.0], [0.0, 0.01, 0.0]],
        "base_scenario" => %{
          "id" => "base",
          "spacecraft" => %{
            "id" => "sat_1",
            "dry_mass_kg" => 250.0
          },
          "initial_state" => %{
            "position_km" => [7000.0, 0.0, 0.0],
            "velocity_km_s" => [0.0, 7.5, 0.0],
            "epoch" => %{
              "seconds_since_j2000" => 0.0,
              "scale" => "tdb"
            },
            "frame" => "earth_inertial_j2000"
          },
          "duration_s" => 120.0,
          "output_step_s" => 60.0
        }
      }
    }
  end

  defp monte_carlo_manifest do
    %{
      "schema_version" => 1,
      "study_id" => "study_benchmark_monte_carlo",
      "central_body" => "earth",
      "propagator" => "two_body",
      "propagator_opts" => %{"max_step_s" => 10.0},
      "outputs" => ["trajectories"],
      "constraints" => [
        %{
          "id" => "minimum_altitude",
          "metric" => "min_altitude_km",
          "operator" => ">=",
          "value" => 600.0
        }
      ],
      "monte_carlo" => %{
        "generator" => "state_vector_dispersion",
        "id_prefix" => "dispersion",
        "seed" => 12_345,
        "count" => 1,
        "position_sigma_km" => [0.1, 0.1, 0.05],
        "velocity_sigma_km_s" => [0.0001, 0.0001, 0.00005],
        "objective" => "min_altitude_km",
        "rank_limit" => 2,
        "base_scenario" => %{
          "id" => "base",
          "spacecraft" => %{
            "id" => "sat_1",
            "dry_mass_kg" => 250.0
          },
          "initial_state" => %{
            "position_km" => [7000.0, 0.0, 0.0],
            "velocity_km_s" => [0.0, 7.546053290107541, 0.0],
            "epoch" => %{
              "seconds_since_j2000" => 0.0,
              "scale" => "tdb"
            },
            "frame" => "earth_inertial_j2000"
          },
          "duration_s" => 120.0,
          "output_step_s" => 60.0
        }
      }
    }
  end

  defp json_safe(value) do
    value
    |> :json.encode()
    |> IO.iodata_to_binary()
    |> :json.decode()
  end
end
