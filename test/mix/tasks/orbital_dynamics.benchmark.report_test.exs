defmodule Mix.Tasks.OrbitalDynamics.Benchmark.ReportTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  test "prints a saved benchmark report with operational scale comparisons" do
    path = Path.join(System.tmp_dir!(), "orbital_dynamics_benchmark_report_task.json")

    on_exit(fn ->
      File.rm(path)
      Mix.Task.reenable("orbital_dynamics.benchmark.report")
    end)

    File.write!(path, :json.encode(artifact()))

    output =
      capture_io(fn ->
        Mix.Task.run("orbital_dynamics.benchmark.report", [
          path,
          "--scale-target",
          "v1_campaign"
        ])
      end)

    assert output =~ "OrbitalDynamics benchmark report"
    assert output =~ "operational scale target: v1_campaign"
    assert output =~ "scale 100 scalar_direct: within_target"
    assert output =~ "distribution local_concurrency_target"
  end

  defp artifact do
    %{
      "schema_version" => 1,
      "generated_at" => "2026-05-13T00:00:00Z",
      "environment" => %{
        "elixir_version" => "1.20.0",
        "otp_release" => "28",
        "schedulers_online" => 8,
        "system_architecture" => "aarch64-apple-darwin"
      },
      "benchmark_options" => %{"counts" => [100]},
      "results" => [
        %{
          "id" => "scalar_direct_100_r1",
          "mode" => "scalar_direct",
          "scenario_count" => 100,
          "sample_count" => 6_100,
          "failure_count" => 0,
          "elapsed_ms" => 40.0,
          "metadata" => %{"samples_per_second" => 152_500.0}
        }
      ]
    }
  end
end
