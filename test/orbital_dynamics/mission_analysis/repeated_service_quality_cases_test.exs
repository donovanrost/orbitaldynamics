defmodule OrbitalDynamics.MissionAnalysis.RepeatedServiceQualityCasesTest do
  use ExUnit.Case, async: true
  alias OrbitalDynamics.MissionAnalysis.RepeatedServiceQualityCases, as: Cases
  alias OrbitalDynamics.MissionAnalysis.Scheduling.{Policy, Reassignment}

  test "independent fixed-time enumeration has hand-checkable assignment, maneuver and battery optima" do
    results = Map.new(Cases.cases(), &{&1["id"], Cases.oracle(&1)})
    assert results["repeated_assignment"]["optimal_value"] == 27
    assert results["repeated_assignment"]["enumerated_count"] == 12
    assert results["maneuver_gap"]["optimal_value"] == 15
    assert results["maneuver_gap"]["rejection_reasons"] == %{"maneuver_gap" => 3}
    assert results["battery_limited"]["optimal_value"] == 18
    assert results["battery_limited"]["rejection_reasons"] == %{"battery_reserve" => 1}
    assert results["battery_recovery"]["optimal_value"] == 25
    assert results["battery_recovery"]["feasible_count"] == 8
  end

  test "each independently optimal witness replays as a fully supported production plan" do
    for config <- Cases.cases() do
      oracle = Cases.oracle(config)
      witness = Map.new(oracle["witness"], &{&1["id"], &1["asset_id"]})

      requests =
        for r <- config["requests"],
            Map.has_key?(witness, r["id"]),
            do: Map.put(r, "allowed_assets", [witness[r["id"]]])

      report = Cases.plan!(Map.put(config, "requests", requests), nil)
      assert Enum.sum(Enum.map(report["activities"], & &1["value"])) == oracle["optimal_value"]
      assert report["attitude_planning"]["planning_status"] == "supported"

      assert Enum.all?(report["activities"], fn a ->
               Enum.all?(a["endpoint_samples"], & &1["feasible"])
             end)
    end
  end

  test "production planners expose both an improvement and a retained known quality gap" do
    greedy = Map.new(Cases.run!(), &{&1["id"], &1})
    repair = Map.new(Cases.run!(Policy.new!(Reassignment, max_trials: 4)), &{&1["id"], &1})
    assert greedy["repeated_assignment"]["planner_value"] == 18
    assert repair["repeated_assignment"]["planner_value"] == 27
    assert repair["repeated_assignment"]["absolute_gap"] == 0
    assert repair["maneuver_gap"]["planner_value"] == 10
    assert repair["maneuver_gap"]["absolute_gap"] == 5
    assert greedy["battery_limited"]["planner_value"] == 18
    assert greedy["battery_recovery"]["planner_value"] == 25
    assert Enum.all?(Map.values(repair), &(&1["planning_status"] == "supported"))
    repeated = Enum.frequencies_by(repair["repeated_assignment"]["activities"], & &1["asset_id"])
    assert repeated == %{"a" => 2, "b" => 1}
  end

  test "oracle cannot recover from an initially violated reserve or assume wrapped-angle geometry" do
    c = hd(Cases.cases())

    for invalid <- [
          Map.put(c, "initial_wh", 1),
          Map.put(c, "initial_wh", 6),
          Map.put(c, "reserve_wh", -1)
        ] do
      assert_raise ArgumentError, ~r/initially valid battery/, fn -> Cases.oracle(invalid) end
    end

    c = update_in(c, ["requests", Access.at(0), "angle_deg"], fn _ -> 350 end)
    assert_raise ArgumentError, ~r/common-axis/, fn -> Cases.oracle(c) end
  end
end
