defmodule Mix.Tasks.OrbitalDynamics.Mission.ResourceTest do
  use ExUnit.Case, async: false
  @moduletag :integration
  import ExUnit.CaptureIO
  alias OrbitalDynamics.MissionAnalysis.ReferenceMission
  alias OrbitalDynamics.MissionAnalysis.Attitude.Reference

  test "resource CLI exposes full energy history and battery reserve headroom" do
    dir = Path.join(System.tmp_dir!(), "resource-cli-#{System.unique_integer([:positive])}")

    on_exit(fn ->
      File.rm_rf!(dir)
      Mix.Task.reenable("orbital_dynamics.mission.attitude")
    end)

    capture_io(fn ->
      Mix.Task.run("orbital_dynamics.mission.attitude", [
        "--study",
        "studies/illumination_energy.json",
        "--output-dir",
        dir
      ])
    end)

    report = dir |> Path.join("report.json") |> File.read!() |> :json.decode()
    resources = report["attitude_planning"]["resource_feasibility"]
    assert resources["status"] == "supported"
    assert report["attitude_planning"]["planning_status"] == "supported"
    assert Enum.map(report["activities"], & &1["request_id"]) == ["illumination-north"]

    for level <- hd(resources["assets"]["demo-1"]["models"])["levels"] do
      assert_in_delta level["state_extrema"]["energy_wh"]["min"], 9.2182518435, 1.0e-8
      assert level["final_state"]["energy_wh"] > 9.9
      assert length(level["samples"]) > 10
      assert level["evaluated_through_s"] == 820_497_850
    end

    assert File.read!(Path.join(dir, "README.md")) =~ "Resource feasibility"
  end

  test "tight initial battery rejects otherwise supported activity but still assesses idle energy" do
    study =
      ReferenceMission.load!("studies/illumination_energy.json")
      |> put_in(["resources", "assets", "demo-1", Access.at(0), "configuration", "initial_wh"], 9)

    mission =
      ReferenceMission.load!("studies/reference_energy.json")
      |> put_in(["requests", Access.at(1), "starts_at_s"], 820_497_661)
      |> put_in(["requests", Access.at(1), "ends_at_s"], 820_497_681)

    report = Reference.run!(mission, study)
    assert report["activities"] == []
    assert report["attitude_planning"]["resource_feasibility"]["status"] == "supported"

    assert Enum.any?(report["selection_decisions"], fn d ->
             Enum.any?(
               Map.get(d["attitude_assessment"], "attempts", []),
               &(&1["reason"] == ":resource_feasibility_violated")
             )
           end)
  end

  test "reference battery configuration refuses overlapping static energy costs" do
    study = ReferenceMission.load!("studies/illumination_energy.json")

    mission =
      ReferenceMission.load!("studies/reference_energy.json")
      |> put_in(["requests", Access.at(0), "resource_costs"], %{"energy_wh" => 1})

    assert_raise ArgumentError, ~r/overlaps static cost energy_wh/, fn ->
      Reference.run!(mission, study)
    end
  end
end
