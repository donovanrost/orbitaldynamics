defmodule Mix.Tasks.OrbitalDynamics.Mission.RunTest do
  use ExUnit.Case, async: false
  @moduletag :integration
  import ExUnit.CaptureIO

  setup do
    on_exit(fn -> Mix.Task.reenable("orbital_dynamics.mission.run") end)
    :ok
  end

  test "writes the complete standalone analysis report" do
    directory = Path.join(System.tmp_dir!(), "mission-cli-#{System.unique_integer([:positive])}")
    on_exit(fn -> File.rm_rf!(directory) end)
    output = Path.join(directory, "report.json")

    text =
      capture_io(fn ->
        Mix.Task.run("orbital_dynamics.mission.run", [
          "--manifest",
          "studies/reference_illumination.json",
          "--output",
          output
        ])
      end)

    assert text =~ "1/1 requests scheduled"

    assert %{"format" => "mission_analysis.v1", "activities" => [_]} =
             output |> File.read!() |> :json.decode()
  end

  test "requires distinct manifest/output paths and rejects unrecognized options" do
    assert_raise Mix.Error, fn -> Mix.Tasks.OrbitalDynamics.Mission.Run.run(["--unknown"]) end

    assert_raise Mix.Error, fn ->
      Mix.Tasks.OrbitalDynamics.Mission.Run.run([
        "--manifest",
        "studies/reference_imaging.json",
        "--output",
        "studies/reference_imaging.json"
      ])
    end
  end
end
