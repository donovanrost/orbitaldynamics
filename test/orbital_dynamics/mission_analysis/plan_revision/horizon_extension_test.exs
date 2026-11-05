defmodule OrbitalDynamics.MissionAnalysis.PlanRevision.HorizonExtensionTest do
  use ExUnit.Case, async: true
  alias OrbitalDynamics.MissionAnalysis.ReferenceMission
  alias OrbitalDynamics.MissionAnalysis.PlanRevision.{Reference, Prediction, Advance}
  alias OrbitalDynamics.MissionAnalysis.PlanValidation.{Checker, Operations}
  alias OrbitalDynamics.MissionAnalysis.Operations.Scenario
  alias OrbitalDynamics.IndependentPlanFixture, as: F
  @epoch 820_497_600

  defp inputs do
    m = ReferenceMission.load!("studies/automatic_wheel_maintenance.json")
    s = ReferenceMission.load!("studies/automatic_wheel_maintenance_planning.json")
    # Battery-only synthetic case isolates extension from finite wheel capacity.
    s =
      update_in(
        s,
        ["resources", "assets", "demo-3"],
        &Enum.filter(&1, fn x -> x["model"] == "battery" end)
      )

    s =
      Map.delete(s, "scheduling")
      |> Map.put("rolling_horizon", %{
        "provider" => "reference_j2",
        "sample_step_s" => 10,
        "max_samples_per_asset" => 64
      })

    m = Map.put(m, "duration_s", 120)

    future =
      hd(m["requests"])
      |> Map.merge(%{
        "id" => "future",
        "starts_at_s" => @epoch + 140,
        "ends_at_s" => @epoch + 160,
        "duration_s" => 10,
        "resource_costs" => %{},
        "activity_type" => "service",
        "value" => 2
      })

    m = Map.update!(m, "requests", &(&1 ++ [future]))
    s = put_in(s, ["path_constraints", "assets", "demo-3", "activity_modes", "future"], "work")
    {m, s}
  end

  defp extension(add \\ []),
    do: %{
      "provider" => "reference_j2",
      "ends_at_s" => @epoch + 200,
      "coverage_ends_at_s" => @epoch + 220,
      "add_requests" => add
    }

  defp step(id, t),
    do: %{
      "id" => id,
      "kind" => "advance",
      "expected_status" => "ready_for_review",
      "as_of_s" => @epoch + t,
      "not_executed_request_ids" => [],
      "energy_losses_wh" => %{},
      "protect_request_ids" => [],
      "scheduling" => %{"strategy" => "greedy", "max_trials" => 1}
    }

  test "future demand survives a short horizon and extension preserves history and overlap" do
    {m, s} = inputs()
    root = Reference.create!(m, s)
    assert Checker.snapshot(root)["status"] == "passed"
    first = Advance.run!(root, Prediction.update!(root, @epoch + 60)).revised_snapshot
    assert Enum.any?(first["payload"]["inputs"]["mission"]["requests"], &(&1["id"] == "future"))
    u = Prediction.update!(first, @epoch + 90) |> Map.put("horizon_extension", extension())
    r = Advance.run!(first, u)
    assert r.review["status"] == "ready_for_review"
    child = r.revised_snapshot
    assert Checker.snapshot(child)["status"] == "passed"
    assert child["payload"]["parent_snapshot_id"] == first["snapshot_id"]
    assert Enum.any?(child["payload"]["report"]["activities"], &(&1["request_id"] == "future"))
    assert length(child["payload"]["inputs"]["execution"]["closed_requests"]) == 2
    later = Advance.run!(child, Prediction.update!(child, @epoch + 180))
    assert later.review["status"] == "ready_for_review"

    assert Enum.any?(
             later.revised_snapshot["payload"]["inputs"]["execution"]["closed_requests"],
             &(&1["request"]["id"] == "future" and &1["status"] == "completed")
           )
  end

  test "unknown provider, insufficient coverage, nonaligned mesh and mutated saved predictions reject before planning" do
    {m, s} = inputs()
    root = Reference.create!(m, s)
    u = Prediction.update!(root, @epoch + 90)

    for e <- [
          Map.put(extension(), "provider", "unknown"),
          Map.put(extension(), "coverage_ends_at_s", @epoch + 200),
          Map.put(extension(), "coverage_ends_at_s", @epoch + 221)
        ] do
      r =
        Advance.run!(root, Map.put(u, "horizon_extension", e), fn _, _, _ ->
          flunk("unsupported coverage reached planner")
        end)

      assert r.review["status"] == "horizon_extension_rejected"
      assert r.revised_snapshot == :null
    end

    bad =
      update_in(root, ["payload", "report", "trajectory_coverage", "assets", "demo-3"], fn [
                                                                                             x
                                                                                             | xs
                                                                                           ] ->
        [Map.update!(x, "position_km", fn [v | vs] -> [v + 0.01 | vs] end) | xs]
      end)
      |> F.rehash()

    r =
      Advance.run!(
        bad,
        Prediction.update!(bad, @epoch + 90) |> Map.put("horizon_extension", extension())
      )

    assert r.review["status"] == "horizon_extension_rejected"
  end

  test "new demand, multi-cycle replay and independently compared saved overlap" do
    {m, s} = inputs()

    addition =
      hd(m["requests"])
      |> Map.merge(%{
        "id" => "new",
        "starts_at_s" => @epoch + 170,
        "ends_at_s" => @epoch + 190,
        "duration_s" => 10,
        "resource_costs" => %{},
        "activity_type" => "service",
        "value" => 3
      })

    e = extension([%{"request" => addition, "activity_modes" => %{"demo-3" => "work"}}])

    script = %{
      "scenario_id" => "extension",
      "mission_manifest" => "synthetic.json",
      "planning_study" => "synthetic_planning.json",
      "steps" => [step("extend", 90) |> Map.put("horizon_extension", e), step("later", 195)]
    }

    Process.put(:artifacts, %{})

    r =
      Scenario.run!(m, s, script, fn name, v ->
        Process.put(:artifacts, Map.put(Process.get(:artifacts), name, v))
      end)

    assert r["verification_status"] == "passed"
    a = Process.get(:artifacts)
    assert Operations.validate(r, F.load(a))["status"] == "passed"
    name = "step-01-revised_snapshot.json"

    bad =
      update_in(a[name], ["payload", "report", "trajectory_coverage", "assets", "demo-3"], fn [
                                                                                                x
                                                                                                | xs
                                                                                              ] ->
        [Map.update!(x, "velocity_km_s", fn [v | vs] -> [v + 0.001 | vs] end) | xs]
      end)
      |> F.rehash()

    assert Checker.snapshot(bad)["status"] == "passed"

    assert OrbitalDynamics.MissionAnalysis.PlanValidation.Coverage.overlap(
             a["baseline_snapshot.json"],
             bad,
             "mutated"
           )
           |> Enum.any?(&(&1["code"] == "trajectory_overlap"))
  end
end
