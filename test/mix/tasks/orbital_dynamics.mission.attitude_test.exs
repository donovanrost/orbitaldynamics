defmodule Mix.Tasks.OrbitalDynamics.Mission.AttitudeTest do
  use ExUnit.Case, async: false
  @moduletag :integration
  import ExUnit.CaptureIO
  alias OrbitalDynamics.MissionAnalysis.ReferenceMission

  test "runs relative-path input files and writes attitude-supported profiles and transition evidence" do
    dir = Path.join(System.tmp_dir!(), "attitude-cli-#{System.unique_integer([:positive])}")
    File.mkdir_p!(dir)

    on_exit(fn ->
      File.rm_rf!(dir)
      Mix.Task.reenable("orbital_dynamics.mission.attitude")
    end)

    mission =
      ReferenceMission.load!("studies/reference_attitude.json") |> Map.put("duration_s", 250)

    study =
      ReferenceMission.load!("studies/illumination_attitude.json")
      |> Map.put("mission_manifest", "mission.json")

    File.write!(Path.join(dir, "mission.json"), :json.encode(mission))
    study_path = Path.join(dir, "study.json")
    File.write!(study_path, :json.encode(study))
    out = Path.join(dir, "results")

    output =
      capture_io(fn ->
        Mix.Task.run("orbital_dynamics.mission.attitude", [
          "--study",
          study_path,
          "--output-dir",
          out
        ])
      end)

    assert output =~ "2/2 requests scheduled"
    report = out |> Path.join("report.json") |> File.read!() |> :json.decode()
    assert length(report["attitude_planning"]["transitions"]) == 2
    assert File.read!(Path.join(out, "README.md")) =~ "Declared kinematic assumptions only"
    assert report["execution_boundary"] == "analysis_only_no_command_execution"
  end
end
