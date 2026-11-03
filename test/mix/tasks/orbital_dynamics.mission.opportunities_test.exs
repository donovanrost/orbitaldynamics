defmodule Mix.Tasks.OrbitalDynamics.Mission.OpportunitiesTest do
  use ExUnit.Case, async: false
  @moduletag :integration
  import ExUnit.CaptureIO
  alias OrbitalDynamics.MissionAnalysis.ReferenceMission
  alias OrbitalDynamics.MissionAnalysis.Attitude.Reference

  test "Reflect-like requests pass through conservative opportunities, attitude and full battery replay" do
    dir = Path.join(System.tmp_dir!(), "opportunities-#{System.unique_integer([:positive])}")

    on_exit(fn ->
      File.rm_rf!(dir)
      Mix.Task.reenable("orbital_dynamics.mission.attitude")
    end)

    capture_io(fn ->
      Mix.Task.run("orbital_dynamics.mission.attitude", [
        "--study",
        "studies/illumination_opportunities.json",
        "--output-dir",
        dir
      ])
    end)

    r = dir |> Path.join("report.json") |> File.read!() |> :json.decode()
    assert [a] = r["activities"]
    assert a["request_id"] == "illumination-north"
    assert_in_delta a["starts_at_s"] - 820_497_600, 60.51, 1.0e-5
    assert r["attitude_planning"]["resource_feasibility"]["status"] == "supported"
    assert r["opportunity_search"]["entry_margin_s"] == 0.5
    by_id = Map.new(r["opportunities"], &{&1["id"], &1})
    w = by_id[a["opportunity_id"]]["window_evidence"]
    assert a["starts_at_s"] >= w["starts_at_s"] and a["ends_at_s"] <= w["ends_at_s"]
    assert a["opportunity_evidence"] == w
    assert Enum.all?(w["endpoint_checks"], & &1["feasible"])

    assert Enum.any?(
             r["selection_decisions"],
             &(&1["request_id"] == "illumination-primary" and
                 &1["reason"] == "planning_start_grid_infeasible")
           )

    for analysis <- r["analyses"] do
      e = analysis["opportunity_evidence"]
      assert e["status"] == "partial_under_search_policy"
      assert e["total_evaluation_count"] <= 50000

      assert length(e["event_search"]["function_observations"]) >=
               e["event_search"]["scan_epoch_count"]
    end

    markdown = File.read!(Path.join(dir, "README.md"))
    assert markdown =~ "Conservative opportunities"
    assert markdown =~ "minimum_elevation_deg"
    assert markdown =~ "Declared mission margins"
  end

  test "oversized timing margins explain rejected windows while idle assets still replay resources" do
    study =
      ReferenceMission.load!("studies/illumination_opportunities.json")
      |> put_in(["opportunity_search", "entry_margin_s"], 150)
      |> put_in(["opportunity_search", "exit_margin_s"], 150)

    r = Reference.run!(ReferenceMission.load!("studies/reference_energy.json"), study)
    assert r["opportunities"] == []
    assert r["activities"] == []
    assert Enum.all?(r["requests"], &("removed_by_mission_timing_margins" in &1["reasons"]))
    assert r["attitude_planning"]["resource_feasibility"]["status"] == "supported"
  end
end
