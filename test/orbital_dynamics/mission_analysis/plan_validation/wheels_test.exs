defmodule OrbitalDynamics.MissionAnalysis.PlanValidation.WheelsTest do
  use ExUnit.Case, async: true
  alias OrbitalDynamics.MissionAnalysis.{ReferenceMission, ReactionWheelQualityCases}
  alias OrbitalDynamics.MissionAnalysis.PlanRevision.Reference
  alias OrbitalDynamics.MissionAnalysis.PlanValidation.{Checker, Operations}
  alias OrbitalDynamics.MissionAnalysis.Operations.Scenario
  alias OrbitalDynamics.IndependentPlanFixture, as: F

  defp levels,
    do: [
      "payload",
      "report",
      "attitude_planning",
      "resource_feasibility",
      "assets",
      "demo-3",
      "models",
      Access.at(1),
      "levels"
    ]

  defp config,
    do: [
      "payload",
      "inputs",
      "study",
      "resources",
      "assets",
      "demo-3",
      Access.at(1),
      "configuration"
    ]

  setup_all do
    m = ReferenceMission.load!("studies/automatic_wheel_maintenance.json")
    s = ReferenceMission.load!("studies/automatic_wheel_maintenance_planning.json")
    Process.put(:wheel_validation_files, %{})
    script = ReferenceMission.load!("studies/automatic_wheel_maintenance_operations.json")

    ops =
      Scenario.run!(m, s, script, fn name, value ->
        Process.put(
          :wheel_validation_files,
          Map.put(Process.get(:wheel_validation_files), name, value)
        )
      end)

    {:ok,
     mission: m,
     study: s,
     snapshot: Process.get(:wheel_validation_files)["baseline_snapshot.json"],
     files: Process.get(:wheel_validation_files),
     operations: ops}
  end

  defp codes(r), do: Enum.map(r["issues"], & &1["code"])

  defp rejects(s, code) do
    r = s |> F.bind() |> Checker.snapshot()
    assert r["status"] == "failed"
    assert code in codes(r)
    refute "snapshot_content_identity" in codes(r)
  end

  test "independent analytic history checks a selected unload and every execution boundary",
       ctx do
    r = Checker.snapshot(ctx.snapshot)
    assert r["status"] == "passed" and r["issues"] == []

    assert_in_delta Enum.at(r["expected_wheels"]["demo-3"]["wheels"]["final_momentum_nms"], 2),
                    0.9,
                    1.0e-8

    assert Operations.validate(ctx.operations, F.load(ctx.files))["status"] == "passed"
  end

  test "rehashing false sample, motor, final state, extrema or coverage does not evade wheel accounting",
       %{snapshot: s} do
    for {code, change} <- [
          {"wheel_final_state",
           fn l -> put_in(l, ["final_state", "wheel_3_momentum_nms"], 0) end},
          {"wheel_sample_state",
           fn l -> put_in(l, ["samples", Access.at(4), "state", "wheel_3_momentum_nms"], 0.5) end},
          {"wheel_sample_demand",
           fn l ->
             put_in(l, ["samples", Access.at(4), "metrics", "motor_torque_mid_nm"], [0, 0, 0])
           end},
          {"wheel_extrema",
           fn l -> put_in(l, ["state_extrema", "wheel_3_momentum_nms", "max"], 0.5) end},
          {"wheel_coverage", fn l -> Map.update!(l, "samples", &Enum.drop(&1, -1)) end}
        ] do
      rejects(update_in(s, levels(), fn levels -> Enum.map(levels, change) end), code)
    end
  end

  test "missed momentum and motor saturation are found from inputs, independent of reported pass statuses",
       %{snapshot: s} do
    rejects(
      put_in(s, config() ++ ["momentum_capacity_nms"], [1, 1, 0.5]),
      "wheel_momentum_capacity"
    )

    rejects(
      put_in(s, config() ++ ["max_motor_torque_nm"], [0.3, 0.3, 0.01]),
      "wheel_motor_capacity"
    )

    rejects(
      put_in(
        s,
        [
          "payload",
          "inputs",
          "study",
          "path_constraints",
          "assets",
          "demo-3",
          "activity_modes",
          "unload"
        ],
        "idle"
      ),
      "wheel_unload_mode"
    )
  end

  test "signed and permuted coordinate axes are supported with floating components", ctx do
    s =
      put_in(
        ctx.study,
        ["resources", "assets", "demo-3", Access.at(1), "configuration", "wheel_axes_body"],
        [[0.0, 0.0, -1.0], [1.0, 0.0, 0.0], [0.0, 1.0, 0.0]]
      )

    r = Reference.create!(ctx.mission, s) |> Checker.snapshot()
    assert r["status"] == "passed"

    assert_in_delta hd(r["expected_wheels"]["demo-3"]["wheels"]["final_momentum_nms"]),
                    -0.9,
                    1.0e-8
  end

  test "moving paths have independently checked momentum and motor histories" do
    {m, s} = ReactionWheelQualityCases.inputs("feasible_slew")
    r = Reference.create!(m, s) |> Checker.snapshot()
    assert r["status"] == "passed"

    assert r["expected_wheels"]["demo-3"]["wheels"]["scope"] ==
             "sampled_global_momentum_balance_on_declared_kinematics"
  end

  test "coherent child wheel-state mutation passes alone but fails independent execution accounting",
       ctx do
    n = length(ctx.operations["steps"])
    name = "step-#{String.pad_leading(Integer.to_string(n), 2, "0")}-revised_snapshot.json"
    child = ctx.files[name]
    u = List.last(ctx.operations["steps"])["state_update"]
    shift = fn [x, y, z] -> [x, y, z + 0.05] end
    u = update_in(u, ["assets", "demo-3", "wheel_momentum_nms", "wheels"], shift)

    child =
      child
      |> update_in(config() ++ ["initial_momentum_nms"], shift)
      |> put_in(["payload", "inputs", "execution", "last_update"], u)
      |> put_in(["payload", "inputs", "execution", "state_update_sha256"], Checker.digest(u))
      |> update_in(levels(), fn levels ->
        Enum.map(levels, fn l ->
          l
          |> update_in(["initial_state", "wheel_3_momentum_nms"], &(&1 + 0.05))
          |> update_in(["final_state", "wheel_3_momentum_nms"], &(&1 + 0.05))
          |> update_in(["state_extrema", "wheel_3_momentum_nms", "min"], &(&1 + 0.05))
          |> update_in(["state_extrema", "wheel_3_momentum_nms", "max"], &(&1 + 0.05))
          |> update_in(["minimum_margins", "wheel_3_momentum", "margin"], &(&1 - 0.05))
          |> Map.update!("samples", fn samples ->
            Enum.map(samples, fn sample ->
              sample
              |> update_in(["state", "wheel_3_momentum_nms"], &(&1 + 0.05))
              |> update_in(["metrics", "rotor_momentum_mid_nms"], shift)
              |> update_in(["metrics", "total_inertial_angular_momentum_nms"], shift)
              |> Map.update!("checks", fn checks ->
                Enum.map(checks, fn check ->
                  if check["id"] == "wheel_3_momentum",
                    do: Map.update!(check, "margin", &(&1 - 0.05)),
                    else: check
                end)
              end)
            end)
          end)
        end)
      end)
      |> F.bind()

    checked = Checker.snapshot(child)
    assert checked["status"] == "passed", inspect(checked["issues"], limit: 10)

    row =
      List.last(ctx.operations["steps"])
      |> Map.put("state_update", u)
      |> Map.put("accepted_snapshot_id", child["snapshot_id"])
      |> put_in(["review", "revised_snapshot_id"], child["snapshot_id"])

    ops =
      ctx.operations
      |> Map.put("final_snapshot_id", child["snapshot_id"])
      |> Map.put("final_accepted_execution_history", child["payload"]["inputs"]["execution"])
      |> update_in(["steps"], &List.replace_at(&1, -1, row))

    result = Operations.validate(ops, F.load(Map.put(ctx.files, name, child)))
    assert result["status"] == "failed"
    assert "execution_wheel_handoff" in codes(result)
  end
end
