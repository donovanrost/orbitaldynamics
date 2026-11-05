defmodule OrbitalDynamics.MissionAnalysis.ConstellationBenchmarkTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.MissionAnalysis.{
    AssignmentQualityCases,
    ConstellationBenchmark,
    ReferenceMission
  }

  test "exact tiny cases expose the flexible-request greedy assignment trap" do
    cases = Map.new(AssignmentQualityCases.run!(), &{&1["id"], &1})
    assert cases["independent"]["greedy_value"] == 19
    assert cases["independent"]["absolute_gap"] == 0
    assert cases["single_slot_contention"]["optimal_value"] == 10
    trap = cases["flexible_request_trap"]
    assert trap["greedy_value"] == 10
    assert trap["optimal_value"] == 19
    assert trap["absolute_gap"] == 9

    assert Enum.sort_by(trap["optimal_assignment"], & &1["asset_id"]) == [
             %{"asset_id" => "a", "request_id" => "low"},
             %{"asset_id" => "b", "request_id" => "high"}
           ]
  end

  test "incomplete battery evidence stays unknown rather than reporting a numeric reserve" do
    model = %{
      "id" => "battery",
      "status" => "unknown",
      "assumptions" => %{"reserve_wh" => 8},
      "state_comparison" => %{"minimum_state_range" => :null, "final_state_range" => :null}
    }

    report = %{
      "attitude_planning" => %{
        "planning_status" => "unknown",
        "model_evaluation_count" => 0,
        "resource_feasibility" => %{
          "status" => "unknown",
          "model_evaluation_count" => 0,
          "assets" => %{"a" => %{"models" => [model]}}
        }
      },
      "remaining_resource_budgets" => %{"a" => %{}},
      "requests" => [],
      "analyses" => [],
      "opportunities" => [],
      "activities" => [],
      "selection_decisions" => []
    }

    summary = ConstellationBenchmark.summarize(report, %{})
    assert summary["planning_status"] == "unknown"
    assert summary["batteries"]["a"]["minimum_energy_wh"] == :null
    assert summary["batteries"]["a"]["minimum_reserve_margin_wh"] == :null
    assert summary["batteries"]["a"]["final_energy_wh_range"] == :null
  end

  @tag :integration
  @tag timeout: 180_000
  test "physical fixture produces opportunities, supported fleet evidence and honest stage timings" do
    mission = ReferenceMission.load!("studies/small_constellation.json")
    study = ReferenceMission.load!("studies/small_constellation_planning.json")
    {summary, report} = ConstellationBenchmark.run_case!(mission, study, 1)
    assert summary["asset_request_pairs"] == 9
    assert summary["opportunity_count"] > 0
    assert summary["scheduled_count"] == 1
    assert summary["resource_status"] == "supported"
    assert summary["batteries"]["demo-1"]["minimum_reserve_margin_wh"] > 0
    assert summary["opportunity_evaluation_count"] > 0
    assert Enum.all?(summary["timings"], fn {_, ms} -> is_number(ms) and ms >= 0 end)
    stages = Map.drop(summary["timings"], ["total_ms"]) |> Map.values() |> Enum.sum()
    assert summary["timings"]["total_ms"] >= stages
    assert report["attitude_planning"]["horizon_coverage"] != :null
    assert Map.keys(report["attitude_study_configuration"]["resources"]["assets"]) == ["demo-1"]
  end

  test "rejects invalid fleet sizes before planning" do
    assert_raise ArgumentError, fn ->
      ConstellationBenchmark.run_case!(%{"assets" => []}, %{}, 0)
    end

    for size <- [0, -1, 7, 1.5] do
      assert_raise ArgumentError, fn ->
        ConstellationBenchmark.run_case!(%{"assets" => Enum.to_list(1..6)}, %{}, size)
      end
    end
  end
end
