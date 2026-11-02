defmodule Mix.Tasks.OrbitalDynamics.Mission.ResolutionTest do
  use ExUnit.Case, async: false
  @moduletag :integration
  import ExUnit.CaptureIO
  alias OrbitalDynamics.MissionAnalysis.ReferenceMission

  setup do
    dir = Path.join(System.tmp_dir!(), "mission-resolution-#{System.unique_integer([:positive])}")
    File.mkdir_p!(dir)

    on_exit(fn ->
      File.rm_rf!(dir)
      Mix.Task.reenable("orbital_dynamics.mission.resolution")
    end)

    study =
      ReferenceMission.load!("studies/illumination_resolution.json")
      |> Map.put("baseline_manifest", "baseline.json")
      |> Map.update!("levels", &Enum.take(&1, 2))

    baseline =
      ReferenceMission.load!("studies/reference_illumination.json") |> Map.put("duration_s", 60)

    File.write!(Path.join(dir, "baseline.json"), :json.encode(baseline))
    {:ok, dir: dir, study: study}
  end

  test "writes refined windows, margins and comparison artifacts", %{dir: dir, study: study} do
    path = Path.join(dir, "study.json")
    File.write!(path, :json.encode(study))
    out = Path.join(dir, "results")

    text =
      capture_io(fn ->
        Mix.Task.run("orbital_dynamics.mission.resolution", ["--study", path, "--output-dir", out])
      end)

    assert text =~ "2 resolution levels; 0 errors"
    report = out |> Path.join("report.json") |> File.read!() |> :json.decode()
    assert report["format"] == "mission_resolution_study.v1"
    assert report["error_level_count"] == 0
    [request] = hd(report["levels"])["request_evidence"]
    [activity] = request["activities"]
    assert activity["endpoint_evidence_present"]
    assert Enum.any?(activity["sampled_check_margins"], &is_number(&1["minimum_sampled_margin"]))

    for file <- ~w(comparison.csv README.md),
        do: assert(File.stat!(Path.join(out, file)).size > 0)
  end

  test "persists errors and fails the CLI instead of announcing stability", %{
    dir: dir,
    study: study
  } do
    study =
      Map.put(study, "refinement", %{
        "tracking_lookback_s" => 1,
        "time_tolerance_s" => 0.000001,
        "max_extra_evaluations" => 1
      })

    path = Path.join(dir, "study.json")
    File.write!(path, :json.encode(study))
    out = Path.join(dir, "results")

    capture_io(fn ->
      assert_raise Mix.Error, fn ->
        Mix.Task.run("orbital_dynamics.mission.resolution", ["--study", path, "--output-dir", out])
      end
    end)

    report = out |> Path.join("report.json") |> File.read!() |> :json.decode()
    assert report["error_level_count"] > 0
    assert Enum.all?(report["levels"], &(&1["status"] == "error"))
  end
end
