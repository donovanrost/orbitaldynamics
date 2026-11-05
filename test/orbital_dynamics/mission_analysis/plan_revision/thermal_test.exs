defmodule OrbitalDynamics.MissionAnalysis.PlanRevision.ThermalTest do
  use ExUnit.Case, async: true
  alias OrbitalDynamics.MissionAnalysis.ReferenceMission
  alias OrbitalDynamics.MissionAnalysis.PlanRevision.{Reference, Prediction, Advance}
  alias OrbitalDynamics.MissionAnalysis.PlanValidation.{Checker, Operations}
  alias OrbitalDynamics.MissionAnalysis.Operations.Scenario
  alias OrbitalDynamics.IndependentPlanFixture, as: F
  @t 820_497_600
  setup_all do
    m = ReferenceMission.load!("studies/thermal_cooldown_reference.json")
    s = ReferenceMission.load!("studies/thermal_cooldown_planning.json")
    {:ok, mission: m, study: s, root: Reference.create!(m, s)}
  end

  test "automatic declared cooldown enables service and independent analytic checking", c do
    acts = c.root["payload"]["report"]["activities"]
    assert Enum.sort(Enum.map(acts, & &1["request_id"])) == ["cooldown", "service"]
    assert Checker.snapshot(c.root)["status"] == "passed"
    s = Map.delete(c.study, "scheduling")
    without = OrbitalDynamics.MissionAnalysis.Attitude.Reference.run!(c.mission, s)
    refute Enum.any?(without["activities"], &(&1["request_id"] == "service"))
  end

  test "temperature packet is required, quality-bounded and carried through a running cooldown",
       c do
    u = Prediction.update!(c.root, @t + 25)
    assert is_number(u["assets"]["demo-3"]["thermal_temperature_k"]["node"])
    assert u["assets"]["demo-3"]["quality"]["bounds"]["thermal_error_k"] == %{"node" => 0}
    bad = update_in(u, ["assets", "demo-3"], &Map.delete(&1, "thermal_temperature_k"))
    assert_raise ArgumentError, fn -> Advance.run!(c.root, bad) end
    bad = put_in(u, ["assets", "demo-3", "quality", "bounds", "thermal_error_k", "node"], 1)
    assert Advance.run!(c.root, bad).review["status"] == "state_quality_rejected"
    child = Advance.run!(c.root, u).revised_snapshot
    assert Checker.snapshot(child)["status"] == "passed"

    model =
      Enum.find(
        child["payload"]["inputs"]["study"]["resources"]["assets"]["demo-3"],
        &(&1["model"] == "thermal")
      )

    assert model["configuration"]["initial_temperature_k"] ==
             u["assets"]["demo-3"]["thermal_temperature_k"]["node"]
  end

  test "independent checker rejects coherently false temperature histories and missed limits",
       c do
    bad =
      update_in(
        c.root,
        [
          "payload",
          "report",
          "attitude_planning",
          "resource_feasibility",
          "assets",
          "demo-3",
          "models"
        ],
        fn models ->
          Enum.map(models, fn m ->
            if m["id"] == "node",
              do:
                Map.update!(m, "levels", fn levels ->
                  Enum.map(levels, &put_in(&1, ["final_state", "temperature_k"], 300))
                end),
              else: m
          end)
        end
      )
      |> F.rehash()

    assert Enum.any?(Checker.snapshot(bad)["issues"], &(&1["code"] == "thermal_boundary_state"))

    bad =
      update_in(
        c.root,
        ["payload", "inputs", "study", "resources", "assets", "demo-3"],
        fn models ->
          Enum.map(models, fn m ->
            if m["id"] == "node",
              do: put_in(m, ["configuration", "maximum_temperature_k"], 303),
              else: m
          end)
        end
      )
      |> F.bind()

    assert Enum.any?(Checker.snapshot(bad)["issues"], &(&1["code"] == "thermal_hot_limit"))

    bad =
      update_in(
        c.root,
        ["payload", "inputs", "study", "resources", "assets", "demo-3"],
        fn models ->
          Enum.map(models, fn m ->
            if m["id"] == "node",
              do: put_in(m, ["configuration", "phase_heat_w", "activity"], 1),
              else: m
          end)
        end
      )
      |> F.bind()

    assert Checker.snapshot(bad)["status"] == "partial"
  end

  test "multi-cycle thermal replay checks independent handoffs and single-charge cooldown history",
       c do
    script = ReferenceMission.load!("studies/thermal_cooldown_operations.json")
    Process.put(:artifacts, %{})

    report =
      Scenario.run!(c.mission, c.study, script, fn name, v ->
        Process.put(:artifacts, Map.put(Process.get(:artifacts), name, v))
      end)

    assert report["verification_status"] == "passed"
    assert Operations.validate(report, F.load(Process.get(:artifacts)))["status"] == "passed"
    assert report["execution_summary"]["accepted_completion_count"] == 2
  end
end
