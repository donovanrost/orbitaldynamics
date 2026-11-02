defmodule Mix.Tasks.OrbitalDynamics.Mission.PathTest do
  use ExUnit.Case, async: false
  @moduletag :integration
  import ExUnit.CaptureIO
  alias OrbitalDynamics.MissionAnalysis.ReferenceMission

  test "the opt-in path study CLI writes exact modes, check times and final evidence" do
    dir = Path.join(System.tmp_dir!(), "path-cli-#{System.unique_integer([:positive])}")
    File.mkdir_p!(dir)

    on_exit(fn ->
      File.rm_rf!(dir)
      Mix.Task.reenable("orbital_dynamics.mission.attitude")
    end)

    study =
      ReferenceMission.load!("studies/illumination_path.json")
      |> Map.put("mission_manifest", "mission.json")
      |> put_in(["path_constraints", "sample_steps_s"], [5, 1])

    mission =
      ReferenceMission.load!("studies/reference_attitude.json") |> Map.put("duration_s", 250)

    File.write!(Path.join(dir, "mission.json"), :json.encode(mission))
    path = Path.join(dir, "study.json")
    File.write!(path, :json.encode(study))
    out = Path.join(dir, "output")

    text =
      capture_io(fn ->
        Mix.Task.run("orbital_dynamics.mission.attitude", ["--study", path, "--output-dir", out])
      end)

    assert text =~ "1/2 requests scheduled"
    r = out |> Path.join("report.json") |> File.read!() |> :json.decode()
    assert r["attitude_planning"]["path_status"] == "supported_at_tested_epochs"
    assert hd(r["activities"])["path_evidence"]["mode"] == "reflecting"
    assert File.stat!(Path.join(out, "README.md")).size > 0
  end

  test "full-horizon CLI reports terminal phases and keeps a missing terminal unknown" do
    dir = Path.join(System.tmp_dir!(), "horizon-cli-#{System.unique_integer([:positive])}")

    on_exit(fn ->
      File.rm_rf!(dir)
      Mix.Task.reenable("orbital_dynamics.mission.attitude")
    end)

    capture_io(fn ->
      Mix.Task.run("orbital_dynamics.mission.attitude", [
        "--study",
        "studies/illumination_horizon.json",
        "--output-dir",
        dir
      ])
    end)

    report = dir |> Path.join("report.json") |> File.read!() |> :json.decode()
    h = report["attitude_planning"]["horizon_coverage"]
    assert h["status"] == "supported"
    assert h["assets"]["demo-1"]["terminal_path_evidence"]["ends_at_s"] == 820_497_850
    assert List.last(h["assets"]["demo-1"]["terminal_motion"]["phases"])["kind"] == "hold"
    assert File.read!(Path.join(dir, "README.md")) =~ "Full-horizon evidence"

    study =
      ReferenceMission.load!("studies/illumination_horizon.json")
      |> put_in(["horizon", "terminals", "demo-1"], :null)

    mission = ReferenceMission.load!("studies/reference_horizon.json")
    report = OrbitalDynamics.MissionAnalysis.Attitude.Reference.run!(mission, study)
    assert report["activities"] == []
    assert report["attitude_planning"]["horizon_coverage"]["status"] == "unknown"
  end
end
