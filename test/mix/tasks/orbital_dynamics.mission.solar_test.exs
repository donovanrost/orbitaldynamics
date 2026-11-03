defmodule Mix.Tasks.OrbitalDynamics.Mission.SolarTest do
  use ExUnit.Case, async: false
  @moduletag :integration
  import ExUnit.CaptureIO
  alias OrbitalDynamics.MissionAnalysis.ReferenceMission
  alias OrbitalDynamics.MissionAnalysis.Attitude.Reference

  test "solar CLI emits panel/shadow evidence, energy spreads and observed eclipse brackets" do
    dir = Path.join(System.tmp_dir!(), "solar-cli-#{System.unique_integer([:positive])}")

    on_exit(fn ->
      File.rm_rf!(dir)
      Mix.Task.reenable("orbital_dynamics.mission.attitude")
    end)

    capture_io(fn ->
      Mix.Task.run("orbital_dynamics.mission.attitude", [
        "--study",
        "studies/solar_eclipse.json",
        "--output-dir",
        dir
      ])
    end)

    report = dir |> Path.join("report.json") |> File.read!() |> :json.decode()
    assert report["attitude_planning"]["planning_status"] == "supported"
    [solar] = report["solar_generation_diagnostics"]["models"]
    assert length(solar["levels"]) == 3

    for l <- solar["levels"] do
      [entry, exit] = l["shadow_transition_brackets"]
      assert entry["earlier_sample_s"] < entry["later_sample_s"]
      assert entry["later_sample_s"] < exit["earlier_sample_s"]
      assert l["observed_power_range_w"]["min"] == 0
    end

    [battery] = report["attitude_planning"]["resource_feasibility"]["assets"]["demo-1"]["models"]
    spread = battery["state_comparison"]["final_state_range"]["energy_wh"]["spread"]
    assert spread >= 0 and spread < 0.01
    contacts = battery["assumptions"]["contact_search"]
    assert contacts["status"] == "complete_under_search_policy"
    assert contacts["source"]["provenance"]["evaluation"] == "planning_runtime_state_sampler"
    assert Enum.map(contacts["results"], &length(&1["events"])) == [2, 2, 0]

    assert get_in(battery, ["assumptions", "generation_assumptions", "model"]) ==
             "body_fixed_solar_array_v1"

    assert File.read!(Path.join(dir, "README.md")) =~ "Shadow-change brackets"
  end

  test "short solar reference retains a selected activity and unknown hardware never becomes zero generation" do
    study = ReferenceMission.load!("studies/illumination_solar.json")
    mission = ReferenceMission.load!("studies/reference_energy.json")
    report = Reference.run!(mission, study)
    assert Enum.map(report["activities"], & &1["request_id"]) == ["illumination-north"]
    assert report["attitude_planning"]["resource_feasibility"]["status"] == "supported"

    study =
      put_in(
        study,
        [
          "resources",
          "assets",
          "demo-1",
          Access.at(0),
          "configuration",
          "generation",
          "panels",
          Access.at(0),
          "area_m2"
        ],
        :null
      )

    # Fixed request slot bounds the failed-start search; no claim of global infeasibility.
    mission =
      mission
      |> put_in(["requests", Access.at(1), "starts_at_s"], 820_497_661)
      |> put_in(["requests", Access.at(1), "ends_at_s"], 820_497_681)

    report = Reference.run!(mission, study)
    assert report["activities"] == []
    assert report["attitude_planning"]["resource_feasibility"]["status"] == "unknown"
    [m] = report["attitude_planning"]["resource_feasibility"]["assets"]["demo-1"]["models"]
    assert m["state_comparison"]["status"] == "incomplete"
    assert Enum.all?(m["levels"], &(&1["final_state"] == :null))
    markdown = OrbitalDynamics.MissionAnalysis.Attitude.Report.markdown(report)
    assert markdown =~ "cadence comparison incomplete"
    assert markdown =~ "final battery spread unknown Wh"
  end
end
