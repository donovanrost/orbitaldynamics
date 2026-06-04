defmodule OrbitalDynamics.Benchmark.ReportTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Benchmark.Report

  test "declares benchmark report capabilities" do
    assert %{
             report: :propagator_benchmark_summary,
             validation_level: :artifact_contract,
             baseline_modes: ["scalar_direct", "scenario_runner"],
             grouping: [:scenario_count, :mode],
             statistics: statistics,
             known_limits: known_limits
           } = Report.capabilities()

    assert :median_elapsed_ms in statistics
    assert :speedup_vs_baseline in statistics
    assert :median_summary_only in known_limits
    assert :speedup_depends_on_matching_scenario_count_baselines in known_limits
  end

  test "summarizes medians and speedups by scenario count and mode" do
    summary = Report.summarize(artifact())

    assert summary.environment["elixir_version"] == "1.20.0"
    assert summary.benchmark_options["counts"] == [100]

    assert [
             %{
               mode: "exla_cpu",
               scenario_count: 100,
               repetitions: 3,
               failures: 0,
               median_elapsed_ms: 5.0,
               median_samples_per_second: 1_220_000.0,
               speedup_vs_scalar_direct: 8.0,
               speedup_vs_scenario_runner: 2.0
             },
             %{
               mode: "scenario_runner",
               median_elapsed_ms: 10.0,
               speedup_vs_scalar_direct: 4.0,
               speedup_vs_scenario_runner: 1.0
             },
             %{
               mode: "scalar_direct",
               median_elapsed_ms: 40.0,
               speedup_vs_scalar_direct: 1.0,
               speedup_vs_scenario_runner: 0.25
             }
           ] = summary.groups
  end

  test "normalizes clean numeric string benchmark rows" do
    string_artifact =
      update_in(artifact(), ["results"], fn rows ->
        Enum.map(rows, fn row ->
          row
          |> Map.update!("scenario_count", &to_string/1)
          |> Map.update!("sample_count", &to_string/1)
          |> Map.update!("failure_count", &to_string/1)
          |> Map.update!("elapsed_ms", &to_string/1)
          |> update_in(["metadata", "samples_per_second"], &to_string/1)
        end)
      end)

    assert [
             %{
               mode: "exla_cpu",
               scenario_count: 100,
               sample_count: 6_100,
               failures: 0,
               median_elapsed_ms: 5.0,
               median_samples_per_second: 1_220_000.0,
               speedup_vs_scalar_direct: 8.0,
               speedup_vs_scenario_runner: 2.0
             },
             %{
               mode: "scenario_runner",
               median_elapsed_ms: 10.0,
               speedup_vs_scalar_direct: 4.0,
               speedup_vs_scenario_runner: 1.0
             },
             %{
               mode: "scalar_direct",
               median_elapsed_ms: 40.0,
               speedup_vs_scalar_direct: 1.0,
               speedup_vs_scenario_runner: 0.25
             }
           ] = Report.summarize(string_artifact).groups
  end

  test "can attach operational scale comparisons to summary groups" do
    summary = Report.summarize(artifact(), scale_target: :v1_campaign)

    assert summary.operational_scale_target == :v1_campaign

    assert %{
             operational_scale_comparison: %{
               "maturity_level" => "v1_campaign",
               "rows" => rows,
               "distribution_guidance" => %{"status" => "local_concurrency_target"}
             }
           } = Enum.find(summary.groups, &(&1.mode == "scalar_direct"))

    assert %{"metric" => "scenario_count", "status" => "within_target"} =
             Enum.find(rows, &(&1["metric"] == "scenario_count"))

    assert %{"metric" => "local_runtime_s", "observed" => 0.04} =
             Enum.find(rows, &(&1["metric"] == "local_runtime_s"))
  end

  test "reads artifact JSON from disk" do
    path = Path.join(System.tmp_dir!(), "orbital_dynamics_benchmark_report_test.json")
    on_exit(fn -> File.rm(path) end)

    File.write!(path, :json.encode(artifact()))

    assert %{"schema_version" => 1} = Report.read_artifact!(path)
  end

  defp artifact do
    %{
      "schema_version" => 1,
      "generated_at" => "2026-05-13T00:00:00Z",
      "environment" => %{
        "elixir_version" => "1.20.0",
        "otp_release" => "28"
      },
      "benchmark_options" => %{
        "counts" => [100]
      },
      "results" =>
        rows("scalar_direct", [41.0, 40.0, 39.0], [148_000.0, 150_000.0, 152_000.0]) ++
          rows("scenario_runner", [11.0, 10.0, 9.0], [600_000.0, 610_000.0, 620_000.0]) ++
          rows("exla_cpu", [6.0, 5.0, 4.0], [1_200_000.0, 1_220_000.0, 1_240_000.0])
    }
  end

  defp rows(mode, elapsed_ms_values, samples_per_second_values) do
    elapsed_ms_values
    |> Enum.zip(samples_per_second_values)
    |> Enum.with_index(1)
    |> Enum.map(fn {{elapsed_ms, samples_per_second}, repetition} ->
      %{
        "id" => "#{mode}_100_r#{repetition}",
        "mode" => mode,
        "scenario_count" => 100,
        "sample_count" => 6_100,
        "failure_count" => 0,
        "elapsed_ms" => elapsed_ms,
        "metadata" => %{
          "repetition" => repetition,
          "repetitions" => 3,
          "samples_per_second" => samples_per_second
        }
      }
    end)
  end
end
