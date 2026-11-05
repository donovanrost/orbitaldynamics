defmodule OrbitalDynamics.MissionAnalysis.PlanValidation.MovingResourcesTest do
  use ExUnit.Case, async: true
  alias OrbitalDynamics.MissionAnalysis.ReferenceMission, as: M
  alias OrbitalDynamics.MissionAnalysis.PlanRevision.Reference
  alias OrbitalDynamics.MissionAnalysis.PlanValidation.{Checker, Operations, MovingWheels}
  alias OrbitalDynamics.MissionAnalysis.Operations.Scenario
  alias OrbitalDynamics.IndependentPlanFixture, as: F

  setup_all do
    m = M.load!("studies/motion_checkpoint_reference.json")
    s = M.load!("studies/motion_checkpoint_planning.json")
    script = M.load!("studies/motion_checkpoint_operations.json")
    Process.put(:moving_artifacts, %{})

    script =
      update_in(script, ["steps"], fn steps ->
        Enum.flat_map(steps, fn step ->
          if step["id"] == "checkpoint_53" do
            [
              step
              |> Map.put("expected_status", "planning_failed")
              |> put_in(["scheduling", "work_budget"], %{"max_evaluations" => 1}),
              %{
                "id" => "retry_committed_motion",
                "kind" => "retry",
                "expected_status" => "ready_for_review",
                "scheduling" => %{
                  "strategy" => "greedy",
                  "max_trials" => 1,
                  "work_budget" => %{"max_evaluations" => 100_000}
                }
              }
            ]
          else
            [step]
          end
        end)
      end)

    ops =
      Scenario.run!(m, s, script, fn name, value ->
        Process.put(:moving_artifacts, Map.put(Process.get(:moving_artifacts), name, value))
      end)

    files = Process.get(:moving_artifacts)
    {:ok, mission: m, study: s, ops: ops, files: files, snapshot: files["baseline_snapshot.json"]}
  end

  defp levels(id),
    do: [
      "payload",
      "report",
      "attitude_planning",
      "resource_feasibility",
      "assets",
      "demo-3",
      "models",
      Access.filter(&(&1["id"] == id)),
      "levels"
    ]

  defp codes(r), do: Enum.map(r["issues"], & &1["code"])

  defp rejects(s, code) do
    r = s |> F.bind() |> Checker.snapshot()
    assert r["status"] == "failed", inspect(r)
    assert code in codes(r), inspect(r)
    refute "snapshot_content_identity" in codes(r)
  end

  test "all motion phases, repeated clipped checkpoints and a failed-plan retry pass independent resource checking",
       c do
    assert c.ops["verification_status"] == "passed"
    result = Operations.validate(c.ops, F.load(c.files))
    assert result["status"] == "passed", inspect(result["issues"])

    [failed, retry] =
      Enum.filter(c.ops["steps"], &(&1["id"] in ~w(checkpoint_53 retry_committed_motion)))

    assert failed["execution_checkpoint_id"] == retry["execution_checkpoint_id"]
    assert failed["execution_epoch_s"] == retry["execution_epoch_s"]
    assert retry["executed_services"] == []
    assert result["independent_execution_summary"]["accepted_completion_count"] == 1
  end

  test "coherently rehashed moving momentum, torque, limits, kinematics and coverage are rejected",
       c do
    for {code, change} <- [
          {"wheel_sample_state",
           fn l ->
             update_in(
               l,
               ["samples", Access.at(12), "state", "wheel_3_momentum_nms"],
               &(&1 + 0.05)
             )
           end},
          {"wheel_sample_demand",
           fn l ->
             put_in(l, ["samples", Access.at(12), "metrics", "motor_torque_mid_nm"], [5, 5, 5])
           end},
          {"wheel_margins",
           fn l -> put_in(l, ["minimum_margins", "wheel_3_motor_torque", "margin"], 99) end},
          {"wheel_kinematics_binding",
           fn l ->
             put_in(
               l,
               ["samples", Access.at(12), "kinematics", "mid", "angular_velocity_inertial_deg_s"],
               [0, 0, 1]
             )
           end},
          {"wheel_coverage", fn l -> Map.update!(l, "samples", &List.delete_at(&1, 12)) end}
        ] do
      rejects(update_in(c.snapshot, levels("wheels"), fn ls -> Enum.map(ls, change) end), code)
    end

    base = [
      "payload",
      "inputs",
      "study",
      "resources",
      "assets",
      "demo-3",
      Access.filter(&(&1["id"] == "wheels")),
      "configuration"
    ]

    rejects(
      put_in(c.snapshot, base ++ ["momentum_capacity_nms"], [0.01, 0.01, 0.01]),
      "wheel_momentum_capacity"
    )

    rejects(
      put_in(c.snapshot, base ++ ["max_motor_torque_nm"], [0.001, 0.001, 0.001]),
      "wheel_motor_capacity"
    )

    rejects(
      put_in(
        c.snapshot,
        ["payload", "inputs", "study", "attitude", "assets", "demo-3", "initial", "frame"],
        "ecef"
      ),
      "wheel_initial_frame"
    )

    rejects(update_in(c.snapshot, levels("wheels"), &Enum.take(&1, 1)), "wheel_coverage")
  end

  test "battery phase histories reject false samples, phase labels and omitted intervals", c do
    for {code, change} <- [
          {"battery_sample_state",
           fn l ->
             update_in(l, ["samples", Access.at(12), "state", "energy_wh"], &(&1 + 0.01))
           end},
          {"battery_interval_binding",
           fn l -> put_in(l, ["samples", Access.at(12), "phase"], "activity") end},
          {"battery_coverage", fn l -> Map.update!(l, "samples", &List.delete_at(&1, 12)) end}
        ] do
      rejects(update_in(c.snapshot, levels("battery"), fn ls -> Enum.map(ls, change) end), code)
    end

    rejects(update_in(c.snapshot, levels("battery"), &Enum.take(&1, 1)), "battery_coverage")
  end

  test "efficiencies and curtailment are checked with changing phase loads and different terminal mode power",
       c do
    mission =
      update_in(c.mission, ["requests"], fn requests ->
        Enum.map(requests, fn q ->
          update_in(q, ["parameters", "quaternion_wxyz"], fn values ->
            Enum.map(values, &(&1 * -2))
          end)
        end)
      end)

    s =
      update_in(c.study, ["resources", "assets", "demo-3"], fn models ->
        Enum.map(models, fn m ->
          if m["model"] == "battery" do
            m
            |> put_in(["configuration", "generation", "power_w"], 15)
            |> put_in(["configuration", "initial_wh"], 9.99)
            |> put_in(["configuration", "charge_efficiency"], 0.8)
            |> put_in(["configuration", "discharge_efficiency"], 0.7)
          else
            m
          end
        end)
      end)

    s =
      put_in(s, ["path_constraints", "assets", "demo-3", "modes", "terminal_low_power"], %{
        "power_load_w" => 2,
        "optical_behavior" => "inactive"
      })

    s = put_in(s, ["horizon", "terminals", "demo-3", "mode"], "terminal_low_power")
    s = put_in(s, ["attitude", "assets", "demo-3", "initial", "quaternion_wxyz"], [-2, 0, 0, 0])
    result = Reference.create!(mission, s) |> Checker.snapshot()
    assert result["status"] == "passed", inspect(result["issues"])
    assert result["expected_battery"]["demo-3"]["battery"]["curtailed_wh"] > 0
  end

  test "old moving artifacts without kinematic evidence remain partial", c do
    old =
      update_in(c.snapshot, levels("wheels"), fn ls ->
        Enum.map(ls, fn l ->
          Map.update!(l, "samples", fn xs -> Enum.map(xs, &Map.delete(&1, "kinematics")) end)
        end)
      end)

    result = old |> F.bind() |> Checker.snapshot()
    assert result["status"] == "partial"
    assert "wheel_dynamics_unsupported" in codes(result)
  end

  test "independent checker equations agree with all eight frozen body-frame RK4 references" do
    root = "priv/validation/reaction_wheels/"
    inputs = M.load!(root <> "inputs.json")["cases"] |> Map.new(&{&1["id"], &1})
    references = M.load!(root <> "reference.json")["cases"]

    for reference <- references do
      input = inputs[reference["id"]]

      c = %{
        "wheel_axes_body" => input["axes"],
        "principal_moments_kg_m2" => input["inertia"],
        "initial_momentum_nms" => input["initial_momentum"]
      }

      external = Enum.zip_with(input["disturbance"], input["unload"], &(&1 + &2))
      total = MovingWheels.initial_total(c, hd(reference["samples"])["pose"])

      Enum.chunk_every(reference["samples"], 3, 2, :discard)
      |> Enum.reduce(total, fn [a, m, b], total ->
        {next, hs, motors} =
          MovingWheels.interval(
            c,
            [a["pose"], m["pose"], b["pose"]],
            total,
            external,
            b["t"] - a["t"]
          )

        for {pred, expected} <- Enum.zip(hs, [a, m, b]),
            {x, y} <- Enum.zip(pred, expected["momentum_nms"]),
            do: assert_in_delta(x, y, 1.0e-5)

        for {pred, expected} <- Enum.zip(motors, [a, m, b]),
            {x, y} <- Enum.zip(pred, expected["motor_torque_nm"]),
            do: assert_in_delta(x, y, 1.0e-5)

        next
      end)
    end
  end
end
