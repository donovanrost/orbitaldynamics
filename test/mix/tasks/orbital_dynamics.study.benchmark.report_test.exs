defmodule Mix.Tasks.OrbitalDynamics.Study.Benchmark.ReportTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  test "prints a saved study benchmark report" do
    path = Path.join(System.tmp_dir!(), "orbital_dynamics_study_benchmark_report_task.json")

    on_exit(fn ->
      File.rm(path)
      Mix.Task.reenable("orbital_dynamics.study.benchmark.report")
    end)

    File.write!(path, :json.encode(artifact()))

    output =
      capture_io(fn ->
        Mix.Task.run("orbital_dynamics.study.benchmark.report", [path])
      end)

    assert output =~ "OrbitalDynamics study benchmark report"
    assert output =~ "manifest: studies/leo_dispersion_monte_carlo.json"
    assert output =~ "mc count"
    assert output =~ "propagator"
    assert output =~ "conc"
    assert output =~ "chunk"
    assert output =~ "prop ms"
    assert output =~ "over %"
    assert output =~ "sched %"
    assert output =~ "size MB"
    assert output =~ "balance"
    assert output =~ "100.00%"
    assert output =~ "distributed"
    assert output =~ "worker@127.0.0.1:10"
    assert output =~ "fastest for 20: distributed two_body concurrency 8 chunk 100"
  end

  test "prints operational scale target comparisons when requested" do
    path = Path.join(System.tmp_dir!(), "orbital_dynamics_study_benchmark_scale_report_task.json")

    on_exit(fn ->
      File.rm(path)
      Mix.Task.reenable("orbital_dynamics.study.benchmark.report")
    end)

    File.write!(path, :json.encode(artifact()))

    output =
      capture_io(fn ->
        Mix.Task.run("orbital_dynamics.study.benchmark.report", [
          path,
          "--scale-target",
          "v1_campaign"
        ])
      end)

    assert output =~ "operational scale target: v1_campaign"
    assert output =~ "scale 20 local: within_target"
    assert output =~ "scale 20 distributed: within_target"
    assert output =~ "runtime not_evaluated"
  end

  test "prints a machine-readable JSON benchmark summary" do
    path = Path.join(System.tmp_dir!(), "orbital_dynamics_study_benchmark_json_report_task.json")

    on_exit(fn ->
      File.rm(path)
      Mix.Task.reenable("orbital_dynamics.study.benchmark.report")
    end)

    File.write!(path, :json.encode(artifact()))

    output =
      capture_io(fn ->
        Mix.Task.run("orbital_dynamics.study.benchmark.report", [
          path,
          "--scale-target",
          "v1_campaign",
          "--format",
          "json"
        ])
      end)

    assert %{
             "report_type" => "study_benchmark_summary",
             "artifact" => ^path,
             "summary" => %{
               "operational_scale_target" => "v1_campaign",
               "groups" => groups
             }
           } = output |> String.trim() |> :json.decode()

    assert Enum.any?(groups, &(&1["mode"] == "local"))
    assert Enum.all?(groups, &is_map(&1["backend_acceptance"]))
  end

  test "prints benchmark trend reports for multiple saved artifacts" do
    first_path =
      Path.join(System.tmp_dir!(), "orbital_dynamics_study_benchmark_trend_first.json")

    latest_path =
      Path.join(System.tmp_dir!(), "orbital_dynamics_study_benchmark_trend_latest.json")

    on_exit(fn ->
      File.rm(first_path)
      File.rm(latest_path)
      Mix.Task.reenable("orbital_dynamics.study.benchmark.report")
    end)

    File.write!(first_path, :json.encode(artifact()))

    latest =
      artifact()
      |> Map.put("generated_at", "2026-05-21T00:00:00Z")
      |> put_in(
        ["results"],
        [
          row("local", 15.0, 1_300.0, %{"nonode@nohost" => 20}),
          row("distributed", 12.0, 1_600.0, %{
            "nonode@nohost" => 10,
            "worker@127.0.0.1" => 10
          })
        ]
      )

    File.write!(latest_path, :json.encode(latest))

    output =
      capture_io(fn ->
        Mix.Task.run("orbital_dynamics.study.benchmark.report", [
          first_path,
          latest_path,
          "--scale-target",
          "v1_campaign"
        ])
      end)

    assert output =~ "OrbitalDynamics study benchmark trend report"
    assert output =~ "artifact_count: 2"
    assert output =~ "operational scale target: v1_campaign"
    assert output =~ "scale trend status: trend_regressed"
    assert output =~ "delta %"
    assert output =~ "improved"
    assert output =~ "regressed"
    assert output =~ "2026-05-14T00:00:00Z -> 2026-05-21T00:00:00Z"
  end

  test "prints a machine-readable JSON benchmark trend report" do
    first_path =
      Path.join(System.tmp_dir!(), "orbital_dynamics_study_benchmark_json_trend_first.json")

    latest_path =
      Path.join(System.tmp_dir!(), "orbital_dynamics_study_benchmark_json_trend_latest.json")

    on_exit(fn ->
      File.rm(first_path)
      File.rm(latest_path)
      Mix.Task.reenable("orbital_dynamics.study.benchmark.report")
    end)

    File.write!(first_path, :json.encode(artifact()))

    latest =
      artifact()
      |> Map.put("generated_at", "2026-05-21T00:00:00Z")
      |> put_in(["results"], [row("local", 15.0, 1_300.0, %{"nonode@nohost" => 20})])

    File.write!(latest_path, :json.encode(latest))

    output =
      capture_io(fn ->
        Mix.Task.run("orbital_dynamics.study.benchmark.report", [
          first_path,
          latest_path,
          "--scale-target",
          "v1_campaign",
          "--format",
          "json"
        ])
      end)

    assert %{
             "report_type" => "study_benchmark_trend",
             "artifacts" => [^first_path, ^latest_path],
             "summary" => %{
               "artifact_count" => 2,
               "operational_scale_target" => "v1_campaign",
               "operational_scale_trend_comparison" => %{
                 "schema_contract" => "operational_scale_trend_comparison.v1",
                 "status" => "within_target"
               },
               "groups" => groups
             }
           } = output |> String.trim() |> :json.decode()

    assert Enum.any?(groups, &(&1["trend_status"] == "improved"))
  end

  defp artifact do
    %{
      "schema_version" => 1,
      "generated_at" => "2026-05-14T00:00:00Z",
      "manifest" => %{"path" => "studies/leo_dispersion_monte_carlo.json"},
      "benchmark_options" => %{
        "modes" => ["local", "distributed"],
        "propagators" => ["two_body"],
        "repetitions" => 1,
        "monte_carlo_counts" => [20],
        "task_chunk_sizes" => [100],
        "max_concurrencies" => [8]
      },
      "results" => [
        row("local", 20.0, 1_000.0, %{"nonode@nohost" => 20}),
        row("distributed", 10.0, 2_000.0, %{
          "nonode@nohost" => 10,
          "worker@127.0.0.1" => 10
        })
      ]
    }
  end

  defp row(mode, duration_ms, scenarios_per_second, per_node_counts) do
    %{
      "id" => "leo_#{mode}_20_r1",
      "mode" => mode,
      "propagator" => "two_body",
      "monte_carlo_count" => 20,
      "task_chunk_size" => 100,
      "max_concurrency" => 8,
      "effective_task_concurrency" => if(mode == "local", do: 8, else: 16),
      "repetition" => 1,
      "repetitions" => 1,
      "duration_ms" => duration_ms,
      "propagation_ms" => duration_ms - 2.0,
      "event_detection_ms" => 1.0,
      "artifact_build_ms" => 1.0,
      "overhead_ms" => 1.0,
      "overhead_percent" => 1.0 / duration_ms * 100.0,
      "artifact_body_bytes" => if(mode == "local", do: 20_000, else: 10_000),
      "artifact_size_mb" => if(mode == "local", do: 0.02, else: 0.01),
      "artifact_bytes_per_scenario" => if(mode == "local", do: 1_000.0, else: 500.0),
      "payload_top_level_key_count" => 18,
      "scenario_count" => 20,
      "trajectory_count" => 20,
      "failure_count" => 0,
      "scenarios_per_second" => scenarios_per_second,
      "per_node_trajectory_counts" => per_node_counts,
      "matches_baseline" => true
    }
  end
end
