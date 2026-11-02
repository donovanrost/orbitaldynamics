defmodule Mix.Tasks.OrbitalDynamics.Mission.SweepTest do
  use ExUnit.Case, async: false
  @moduletag :integration
  import ExUnit.CaptureIO
  alias OrbitalDynamics.MissionAnalysis.ReferenceMission

  test "runs a relative-path study and writes portable comparison artifacts" do
    dir = Path.join(System.tmp_dir!(), "mission-sweep-#{System.unique_integer([:positive])}")
    File.mkdir_p!(dir)

    on_exit(fn ->
      File.rm_rf!(dir)
      Mix.Task.reenable("orbital_dynamics.mission.sweep")
    end)

    base = ReferenceMission.load!("studies/reference_illumination.json")
    File.write!(Path.join(dir, "base.json"), :json.encode(base))

    study = %{
      "study_id" => "cli-trade",
      "baseline_manifest" => "base.json",
      "max_cases" => 2,
      "axes" => [
        %{
          "id" => "resolution",
          "cases" => [
            %{
              "id" => "low",
              "updates" => [
                %{
                  "path" => ["requests", 0, "parameters", "minimum_irradiance_w_m2"],
                  "value" => 0.0001
                }
              ]
            },
            %{
              "id" => "high",
              "updates" => [
                %{
                  "path" => ["requests", 0, "parameters", "minimum_irradiance_w_m2"],
                  "value" => 100
                }
              ]
            }
          ]
        }
      ]
    }

    path = Path.join(dir, "study.json")
    File.write!(path, :json.encode(study))
    output = Path.join(dir, "output")

    text =
      capture_io(fn ->
        Mix.Task.run("orbital_dynamics.mission.sweep", ["--study", path, "--output-dir", output])
      end)

    assert text =~ "2 cases + baseline; 0 case errors"
    report = output |> Path.join("report.json") |> File.read!() |> :json.decode()
    assert report["case_count"] == 2
    assert Enum.map(report["cases"], & &1["summary"]["supported_request_count"]) == [1, 0]

    for name <- ~w(comparison.csv metrics.csv checks.csv README.md),
        do: assert(File.stat!(Path.join(output, name)).size > 0)
  end

  test "baseline command writes independent comparison results" do
    path = Path.join(System.tmp_dir!(), "baseline-cli-#{System.unique_integer([:positive])}.json")

    on_exit(fn ->
      File.rm(path)
      Mix.Task.reenable("orbital_dynamics.mission.check_baseline")
    end)

    output =
      capture_io(fn ->
        Mix.Task.run("orbital_dynamics.mission.check_baseline", ["--output", path])
      end)

    assert output =~ "Orekit baseline: pass; 301 samples"
    assert %{"status" => "pass"} = path |> File.read!() |> :json.decode()
  end
end
