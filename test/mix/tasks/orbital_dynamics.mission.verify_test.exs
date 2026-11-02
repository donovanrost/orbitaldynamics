defmodule Mix.Tasks.OrbitalDynamics.Mission.VerifyTest do
  use ExUnit.Case, async: false
  @moduletag :integration
  import ExUnit.CaptureIO

  test "packages independent evidence separately from frozen internal scenarios" do
    dir =
      Path.join(System.tmp_dir!(), "verification-baseline-#{System.unique_integer([:positive])}")

    on_exit(fn ->
      File.rm_rf!(dir)
      Mix.Task.reenable("orbital_dynamics.mission.verify")
    end)

    output =
      capture_io(fn -> Mix.Task.run("orbital_dynamics.mission.verify", ["--output-dir", dir]) end)

    assert output =~ "Reference numerical baseline: pass"
    r = dir |> Path.join("report.json") |> File.read!() |> :json.decode()
    assert r["status"] == "pass"
    assert r["orbit_geometry"]["status"] == "pass"
    assert r["attitude_path_numerics"]["status"] == "pass"

    assert Enum.map(r["frozen_scenarios"]["cases"], & &1["id"]) == [
             "acquisition-and-tracking",
             "path-rejected-transition",
             "unknown-optics"
           ]

    assert Enum.all?(
             r["frozen_scenarios"]["cases"],
             &(&1["classification"] == "internal_end_to_end_regression_not_external_validation")
           )

    assert File.read!(Path.join(dir, "README.md")) =~ "not proven false positives"
  end
end
