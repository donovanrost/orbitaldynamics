defmodule OrbitalDynamics.MissionAnalysis.ServiceWorkloadTest do
  use ExUnit.Case, async: true
  alias OrbitalDynamics.MissionAnalysis.ServiceWorkload

  test "inter-service net energy is signed and unknown cadence evidence stays unknown" do
    activities = [
      %{"request_id" => "first", "ends_at_s" => 10},
      %{"request_id" => "next", "starts_at_s" => 20}
    ]

    level = fn step, from, to ->
      %{
        "sample_step_s" => step,
        "uncovered_intervals" => [],
        "samples" => [
          %{"epoch_s" => 10, "state" => %{"energy_wh" => from}},
          %{"epoch_s" => 20, "state" => %{"energy_wh" => to}}
        ]
      }
    end

    [gap] = ServiceWorkload.recovery_gaps(activities, [level.(2, 3, 4), level.(1, 3, 4.1)])
    assert gap["net_energy_change_wh_range"]["min"] == 1
    assert_in_delta gap["net_energy_change_wh_range"]["max"], 1.1, 1.0e-12
    [loss] = ServiceWorkload.recovery_gaps(activities, [level.(1, 4, 3)])
    assert loss["net_energy_change_wh_range"] == %{"min" => -1, "max" => -1}

    [unknown] =
      ServiceWorkload.recovery_gaps(activities, [
        level.(2, 3, 4),
        Map.put(level.(1, 3, 4), "samples", [])
      ])

    assert unknown["status"] == "unknown"
    assert unknown["net_energy_change_wh_range"] == :null

    [uncovered] =
      ServiceWorkload.recovery_gaps(activities, [
        Map.put(level.(1, 3, 4), "uncovered_intervals", [%{}])
      ])

    assert uncovered["status"] == "unknown"
  end

  test "trial cap is validated before comparison" do
    assert_raise ArgumentError, fn -> ServiceWorkload.run!(%{}, %{}, 0) end
  end

  @tag :integration
  @tag timeout: 180_000
  test "orbital workload exercises repeated services, recovery and resource rejections without tokens" do
    alias OrbitalDynamics.MissionAnalysis.{ReferenceMission, ConstellationBenchmark}
    mission = ReferenceMission.load!("studies/repeated_service.json")
    study = ReferenceMission.load!("studies/repeated_service_planning.json")
    assert Enum.all?(mission["assets"], &(&1["resource_budgets"] == %{}))
    assert Enum.all?(mission["requests"], &(&1["resource_costs"] == %{}))

    {summary, report} =
      ConstellationBenchmark.run_case!(mission, study, length(mission["assets"]))

    diagnostics = ServiceWorkload.diagnostics(report)
    assert summary["planning_status"] == "supported"
    assert summary["scheduled_count"] > summary["asset_count"]
    assert Enum.count(diagnostics["activities_per_asset"], fn {_, n} -> n > 1 end) >= 2
    assert diagnostics["placement_rejection_reasons"][":resource_feasibility_violated"] > 0
    assert diagnostics["nonzero_slew_count"] > summary["asset_count"]
    assert diagnostics["minimum_transition_time_margin_s"] >= 0
    assert Enum.all?(summary["batteries"], fn {_, b} -> b["minimum_reserve_margin_wh"] >= 0 end)
    gaps = diagnostics["inter_service_energy"] |> Map.values() |> List.flatten()
    assert gaps != []

    assert Enum.all?(
             gaps,
             &(&1["status"] == "known_at_tested_cadences" and
                 &1["net_energy_change_wh_range"]["min"] > 0)
           )
  end
end
