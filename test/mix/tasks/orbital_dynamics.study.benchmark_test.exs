defmodule Mix.Tasks.OrbitalDynamics.Study.BenchmarkTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  test "runs a study benchmark and writes an artifact" do
    manifest_path =
      Path.join(System.tmp_dir!(), "orbital_dynamics_study_benchmark_task_manifest.json")

    output_path =
      Path.join(System.tmp_dir!(), "orbital_dynamics_study_benchmark_task_result.json")

    on_exit(fn ->
      File.rm(manifest_path)
      File.rm(output_path)
      Mix.Task.reenable("orbital_dynamics.study.benchmark")
    end)

    File.write!(manifest_path, :json.encode(manifest()) |> IO.iodata_to_binary())

    output =
      capture_io(fn ->
        Mix.Task.run("orbital_dynamics.study.benchmark", [
          "--manifest",
          manifest_path,
          "--mode",
          "local",
          "--repetitions",
          "2",
          "--task-chunk-size",
          "2",
          "--max-concurrency",
          "2",
          "--output",
          output_path
        ])
      end)

    assert output =~ "OrbitalDynamics study benchmark"
    assert output =~ "summary"
    assert output =~ "Wrote study benchmark artifact"

    artifact = output_path |> File.read!() |> :json.decode()
    assert artifact["benchmark_options"]["modes"] == ["local"]
    assert artifact["benchmark_options"]["task_chunk_size"] == 2
    assert artifact["benchmark_options"]["max_concurrency"] == 2
    refute Map.has_key?(artifact["benchmark_options"], "task_supervisor_node")
    assert length(artifact["results"]) == 2
    assert Enum.all?(artifact["results"], &(&1["matches_baseline"] == true))
  end

  test "runs monte carlo count variants" do
    manifest_path =
      Path.join(System.tmp_dir!(), "orbital_dynamics_study_benchmark_task_mc_manifest.json")

    on_exit(fn ->
      File.rm(manifest_path)
      Mix.Task.reenable("orbital_dynamics.study.benchmark")
    end)

    File.write!(manifest_path, :json.encode(monte_carlo_manifest()) |> IO.iodata_to_binary())

    output =
      capture_io(fn ->
        Mix.Task.run("orbital_dynamics.study.benchmark", [
          "--manifest",
          manifest_path,
          "--mode",
          "local",
          "--monte-carlo-counts",
          "2,3",
          "--propagators",
          "two_body,two_body_nx_compiled",
          "--task-chunk-sizes",
          "1,2",
          "--max-concurrencies",
          "1,2"
        ])
      end)

    assert output =~ "mc count"
    assert output =~ "propagator"
    assert output =~ "conc"
    assert output =~ "chunk"
    assert output =~ "propagator two_body"
    assert output =~ "propagator two_body_nx_compiled"
    assert output =~ "local count 2: propagator two_body, max concurrency 1"
    assert output =~ "local count 2: propagator two_body_nx_compiled, max concurrency 2"
    assert output =~ "local count 3: propagator two_body, max concurrency 1"
    assert output =~ "local count 3: propagator two_body_nx_compiled, max concurrency 2"
    assert output =~ "scenarios/s"
    assert output =~ "scheduler utilization"
  end

  test "keeps all repeated mode options" do
    manifest_path =
      Path.join(System.tmp_dir!(), "orbital_dynamics_study_benchmark_task_modes_manifest.json")

    on_exit(fn ->
      File.rm(manifest_path)
      Mix.Task.reenable("orbital_dynamics.study.benchmark")
    end)

    File.write!(manifest_path, :json.encode(manifest()) |> IO.iodata_to_binary())

    assert_raise Mix.Error, ~r/unsupported_modes.*bogus/, fn ->
      capture_io(fn ->
        Mix.Task.run("orbital_dynamics.study.benchmark", [
          "--manifest",
          manifest_path,
          "--mode",
          "bogus",
          "--mode",
          "local"
        ])
      end)
    end
  end

  defp manifest do
    %{
      "schema_version" => 1,
      "study_id" => "study_benchmark_task",
      "central_body" => "earth",
      "propagator" => "two_body",
      "propagator_opts" => %{"max_step_s" => 10.0},
      "outputs" => ["trajectories"],
      "scenarios" => [
        %{
          "id" => "scenario_1",
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
      ]
    }
  end

  defp monte_carlo_manifest do
    %{
      "schema_version" => 1,
      "study_id" => "study_benchmark_task_mc",
      "central_body" => "earth",
      "propagator" => "two_body",
      "propagator_opts" => %{"max_step_s" => 10.0},
      "outputs" => ["trajectories"],
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
end
