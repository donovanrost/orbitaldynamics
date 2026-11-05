defmodule OrbitalDynamics.MissionAnalysis.Resource.ReactionWheelReferenceTest do
  use ExUnit.Case, async: true
  alias OrbitalDynamics.MissionAnalysis.ReactionWheelQualityCases
  alias OrbitalDynamics.MissionAnalysis.Resource.ReactionWheels, as: Wheels
  alias OrbitalDynamics.MissionAnalysis.Attitude.Reference, as: Planner
  alias OrbitalDynamics.MissionAnalysis.PlanRevision.{Reference, Prediction, Advance, Snapshot}
  alias OrbitalDynamics.MissionAnalysis.Operations.Scenario
  alias OrbitalDynamics.MissionAnalysis.PlanValidation.{Checker, Operations}

  setup_all do
    {m, s} = ReactionWheelQualityCases.inputs("unloaded")
    snapshot = Reference.create!(m, s)
    {:ok, mission: m, study: s, snapshot: snapshot}
  end

  defp wheel_levels(r),
    do:
      r["attitude_planning"]["resource_feasibility"]["assets"]["demo-3"]["models"]
      |> Enum.find(&(&1["id"] == "wheels"))
      |> Map.fetch!("levels")

  test "reference cases independently match slew conservation, disturbance saturation and actual external unloading",
       %{snapshot: s} do
    result = ReactionWheelQualityCases.run!()
    assert result["status"] == "passed"
    [slew, saturated, unloaded] = result["cases"]
    assert slew["scheduled_request_ids"] == ["service"]
    assert saturated["planning_status"] == "violated" and saturated["scheduled_request_ids"] == []
    assert unloaded["scheduled_request_ids"] == ["unload", "service"]

    for level <- slew["wheel_levels"] do
      assert_in_delta level["state_extrema"]["wheel_3_momentum_nms"]["min"],
                      -50 * 2 * :math.pi() / 180,
                      1.0e-8

      assert_in_delta level["state_extrema"]["wheel_3_momentum_nms"]["max"],
                      50 * 2 * :math.pi() / 180,
                      1.0e-8
    end

    for l <- wheel_levels(s["payload"]["report"]),
        do: assert_in_delta(elem(Wheels.vector(l["final_state"]), 2), 0.9, 1.0e-8)
  end

  test "wheel state survives an advance and a later same-horizon replan without resetting or replaying the unload",
       %{snapshot: s, mission: m} do
    t = m["epoch_s"] + 60
    u = Prediction.update!(s, t)
    assert u["completed_request_ids"] == ["unload"]
    assert_in_delta Enum.at(u["assets"]["demo-3"]["wheel_momentum_nms"]["wheels"], 2), 0.1, 1.0e-8
    r = Advance.run!(s, %{u | "protect_request_ids" => ["service"]})
    assert r.review["status"] == "ready_for_review"
    child = r.revised_snapshot
    assert Reference.source!(child)
    [battery, wheels] = child["payload"]["inputs"]["study"]["resources"]["assets"]["demo-3"]
    refute Map.has_key?(wheels["configuration"], "initial_wh")
    assert_in_delta Enum.at(wheels["configuration"]["initial_momentum_nms"], 2), 0.1, 1.0e-8
    assert_in_delta battery["configuration"]["initial_wh"], 10 - 12 * 20 / 3600, 1.0e-8

    assert child["payload"]["inputs"]["mission"]["assets"]
           |> hd()
           |> get_in(["resource_budgets", "unload_tokens"]) == 0

    assert Enum.map(r.candidate_report["activities"], & &1["request_id"]) == ["service"]

    for l <- wheel_levels(r.candidate_report),
        do: assert_in_delta(elem(Wheels.vector(l["final_state"]), 2), 0.9, 1.0e-8)

    change = %{
      "revision_id" => "retain_wheel_state",
      "protect_request_ids" => [],
      "add_requests" => [],
      "unavailable_asset_ids" => [],
      "scheduling" => %{"strategy" => "greedy", "max_trials" => 1}
    }

    again = Reference.revise!(child, change)
    assert again.review["status"] == "ready_for_review"

    assert again.revised_snapshot["payload"]["inputs"]["execution"] ==
             child["payload"]["inputs"]["execution"]

    for l <- wheel_levels(again.candidate_report),
        do: assert_in_delta(elem(Wheels.vector(l["final_state"]), 2), 0.9, 1.0e-8)

    for bad <- [
          update_in(u, ["assets", "demo-3"], &Map.delete(&1, "wheel_momentum_nms")),
          put_in(u, ["assets", "demo-3", "wheel_momentum_nms", "wheels"], [0, 0])
        ] do
      assert_raise ArgumentError, fn -> Advance.run!(s, bad) end
    end

    # The independent checker binds the new state structurally and independently checks stationary wheel accounting.
    assert Checker.snapshot(child)["status"] == "passed"
  end

  test "scripted execution replay carries the same rotor state and the validator independently checks stationary wheel accounting",
       %{mission: m, study: study} do
    script = %{
      "scenario_id" => "wheel_replay",
      "mission_manifest" => "wheel_momentum_reference.json",
      "planning_study" => "wheel_momentum_planning.json",
      "steps" => [
        %{
          "id" => "execute_unload",
          "kind" => "advance",
          "expected_status" => "ready_for_review",
          "as_of_s" => m["epoch_s"] + 60,
          "not_executed_request_ids" => [],
          "energy_losses_wh" => %{},
          "protect_request_ids" => ["service"],
          "scheduling" => %{"strategy" => "greedy", "max_trials" => 1}
        }
      ]
    }

    Process.put(:wheel_artifacts, %{})

    r =
      Scenario.run!(m, study, script, fn name, v ->
        Process.put(:wheel_artifacts, Map.put(Process.get(:wheel_artifacts), name, v))
      end)

    assert r["verification_status"] == "passed" and r["run_status"] == "completed"
    u = hd(r["steps"])["state_update"]
    assert_in_delta Enum.at(u["assets"]["demo-3"]["wheel_momentum_nms"]["wheels"], 2), 0.1, 1.0e-8
    files = Process.get(:wheel_artifacts)
    checked = Operations.validate(r, fn name -> Map.fetch(files, name) end)
    assert checked["status"] == "passed"
    assert Enum.all?(checked["issues"], &(&1["severity"] == "unsupported"))
  end

  test "unloading has real costs and cannot be skipped or placed in an ordinary mode", %{
    snapshot: snapshot,
    mission: m,
    study: s
  } do
    zero = put_in(m, ["assets", Access.at(0), "resource_budgets", "unload_tokens"], 0)
    assert {:error, _} = Planner.run_profiled(zero, s)

    wrong =
      put_in(s, ["path_constraints", "assets", "demo-3", "activity_modes", "unload"], "idle")

    assert {:error, _} = Planner.run_profiled(m, wrong)
    u = Prediction.update!(snapshot, m["epoch_s"] + 40)
    u = %{u | "completed_request_ids" => [], "not_executed_request_ids" => ["unload"]}
    # Declare the state after holding rather than unloading: h = 0.02 * 40.
    u = put_in(u, ["assets", "demo-3", "wheel_momentum_nms", "wheels"], [0, 0, 0.8])
    u = put_in(u, ["assets", "demo-3", "resource_budgets", "unload_tokens"], 1)
    r = Advance.run!(snapshot, u)
    assert r.review["status"] == "unsupported_revision" and r.revised_snapshot == :null
    assert r.candidate_report["attitude_planning"]["planning_status"] == "violated"
  end

  test "inertia mismatch and duplicate arrays cannot introduce ambiguous physics", %{
    mission: m,
    study: s
  } do
    bad =
      put_in(
        s,
        [
          "resources",
          "assets",
          "demo-3",
          Access.at(1),
          "configuration",
          "principal_moments_kg_m2"
        ],
        [40, 50, 50]
      )

    assert {:error, _} = Planner.run_profiled(m, bad)

    duplicate =
      update_in(s, ["resources", "assets", "demo-3"], fn [b, w] ->
        [b, w, Map.put(w, "id", "other_wheels")]
      end)

    assert {:error, _} = Planner.run_profiled(m, duplicate)
    assert Snapshot.verify!(Reference.create!(m, s))
  end
end
