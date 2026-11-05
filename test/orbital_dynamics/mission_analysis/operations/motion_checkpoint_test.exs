defmodule OrbitalDynamics.MissionAnalysis.Operations.MotionCheckpointTest do
  use ExUnit.Case, async: true
  alias OrbitalDynamics.MissionAnalysis.ReferenceMission, as: M
  alias OrbitalDynamics.MissionAnalysis.PlanRevision.{Reference, Prediction, Advance}
  alias OrbitalDynamics.MissionAnalysis.Operations.Execution
  alias OrbitalDynamics.MissionAnalysis.Attitude.Quaternion, as: Q
  @epoch 820_497_600

  defp step(t),
    do: %{
      "id" => "motion_checkpoint",
      "as_of_s" => t,
      "not_executed_request_ids" => [],
      "energy_losses_wh" => %{},
      "protect_request_ids" => [],
      "scheduling" => %{"strategy" => "greedy", "max_trials" => 1}
    }

  setup_all do
    m =
      M.load!("studies/automatic_wheel_maintenance.json")
      |> Map.put("duration_s", 140)
      |> Map.update!("requests", &Enum.filter(&1, fn r -> r["id"] == "service" end))

    m =
      update_in(m, ["requests"], fn [r] ->
        [
          put_in(r, ["parameters", "quaternion_wxyz"], [
            :math.cos(:math.pi() / 9),
            0,
            0,
            :math.sin(:math.pi() / 9)
          ])
        ]
      end)

    s =
      M.load!("studies/automatic_wheel_maintenance_planning.json")
      |> Map.put("scheduling", %{"strategy" => "greedy", "max_trials" => 1})
      |> put_in(["horizon", "ends_at_s"], @epoch + 140)
      |> put_in(["path_constraints", "assets", "demo-3", "activity_modes"], %{"service" => "work"})

    s =
      update_in(s, ["resources", "assets", "demo-3"], fn models ->
        Enum.map(models, fn model ->
          case model["model"] do
            "reaction_wheels" ->
              model
              |> put_in(["configuration", "momentum_capacity_nms"], [20, 20, 20])
              |> put_in(["configuration", "disturbance_torque_body_nm"], [0, 0, 0.001])

            "battery" ->
              update_in(
                model,
                ["configuration", "phase_load_w"],
                &Map.merge(&1, %{
                  "hold" => 3,
                  "slew_accelerate" => 15,
                  "slew_cruise" => 8,
                  "slew_decelerate" => 9,
                  "settle" => 4,
                  "brake" => 7,
                  "ramp_to_tracking" => 11,
                  "activity" => 6
                })
              )
          end
        end)
      end)

    root = Reference.create!(m, s)
    assert length(root["payload"]["report"]["activities"]) == 1
    {:ok, root: root, mission: m, study: s}
  end

  defp same_state(a, b) do
    assert Q.distance_deg(a["quaternion_wxyz"], b["quaternion_wxyz"]) < 1.0e-7

    for {x, y} <-
          Enum.zip(a["angular_velocity_inertial_deg_s"], b["angular_velocity_inertial_deg_s"]),
        do: assert_in_delta(x, y, 1.0e-8)

    assert_in_delta a["battery_energy_wh"]["battery"], b["battery_energy_wh"]["battery"], 1.0e-8

    for {x, y} <- Enum.zip(a["wheel_momentum_nms"]["wheels"], b["wheel_momentum_nms"]["wheels"]),
        do: assert_in_delta(x, y, 1.0e-6)

    assert a["resource_budgets"] == b["resource_budgets"]
  end

  test "checkpoints during hold, acceleration, cruise, deceleration, settling, tracking and return preserve the original motion and phase loads",
       c do
    for dt <- [20, 42, 53, 63, 69, 75, 83, 95, 105, 111, 125] do
      t = @epoch + dt
      replay = Execution.run!(c.root, step(t))
      expected = Prediction.state_at!(c.root, t)["demo-3"]
      same_state(replay.predicted_assets["demo-3"], expected)
      child = Advance.run!(c.root, replay.update)
      assert child.review["status"] == "ready_for_review", inspect({dt, child.review})

      for future <- [70, 75, 80, 95, 105, 125, 139], future > dt do
        same_state(
          Prediction.state_at!(child.revised_snapshot, @epoch + future)["demo-3"],
          Prediction.state_at!(c.root, @epoch + future)["demo-3"]
        )
      end
    end
  end

  test "repeated checkpoints retain the acquisition destination and do not restart or brake the slew",
       c do
    first = Execution.run!(c.root, step(@epoch + 42))
    child = Advance.run!(c.root, first.update).revised_snapshot
    second = Execution.run!(child, step(@epoch + 53))

    same_state(
      second.predicted_assets["demo-3"],
      Prediction.state_at!(c.root, @epoch + 53)["demo-3"]
    )

    next = Advance.run!(child, second.update)
    assert next.review["status"] == "ready_for_review"

    assert next.review["protected_activities"] == [
             %{
               "request_id" => "service",
               "asset_id" => "demo-3",
               "starts_at_s" => @epoch + 70,
               "ends_at_s" => @epoch + 80
             }
           ]

    same_state(
      Prediction.state_at!(next.revised_snapshot, @epoch + 69)["demo-3"],
      Prediction.state_at!(c.root, @epoch + 69)["demo-3"]
    )
  end

  test "unconfirmed or mismatched motion and new outages cannot silently abort committed acquisition",
       c do
    replay = Execution.run!(c.root, step(@epoch + 53))

    assert Advance.run!(c.root, Map.delete(replay.update, "motion_source_snapshot_id")).review[
             "status"
           ] == "in_progress_motion_unconfirmed"

    bad =
      put_in(replay.update, ["assets", "demo-3", "angular_velocity_inertial_deg_s"], [0, 0, 0])

    refute Advance.run!(c.root, bad).review["status"] == "ready_for_review"

    bad =
      put_in(replay.update, ["scheduling", "availability"], %{
        "time_scale" => "utc",
        "outages" => [
          %{
            "id" => "blocked",
            "asset_id" => "demo-3",
            "starts_at_s" => @epoch + 65,
            "ends_at_s" => @epoch + 85,
            "scope" => %{"kind" => "all_activities"}
          }
        ]
      })

    assert Advance.run!(c.root, bad).review["status"] == "commitment_conflict"
    # Before acquisition begins, this service remains tentative and may be withheld.
    idle = Execution.run!(c.root, step(@epoch + 20))
    changed = Map.put(idle.update, "scheduling", bad["scheduling"])
    replanned = Advance.run!(c.root, changed)
    assert replanned.review["status"] == "ready_for_review"
    assert replanned.candidate_report["activities"] == []
  end

  test "multi-checkpoint saved-motion lineage is independently reconstructed and coherent phase mutations fail",
       c do
    alias OrbitalDynamics.MissionAnalysis.Operations.Scenario
    alias OrbitalDynamics.MissionAnalysis.PlanValidation.{Checker, Operations}
    alias OrbitalDynamics.IndependentPlanFixture, as: F

    make_script = fn times ->
      %{
        "scenario_id" => "faithful_motion",
        "mission_manifest" => "synthetic.json",
        "planning_study" => "synthetic_planning.json",
        "steps" =>
          Enum.map(times, fn dt ->
            step(@epoch + dt)
            |> Map.put("id", "checkpoint_#{dt}")
            |> Map.put("kind", "advance")
            |> Map.put("expected_status", "ready_for_review")
          end)
      }
    end

    Process.put(:motion_artifacts, %{})

    emit = fn name, v ->
      Process.put(:motion_artifacts, Map.put(Process.get(:motion_artifacts), name, v))
    end

    report =
      Scenario.run!(c.mission, c.study, make_script.([42, 53, 69, 75, 83, 95, 111, 125]), emit)

    assert report["verification_status"] == "passed"
    result = Operations.validate(report, F.load(Process.get(:motion_artifacts)))
    assert result["status"] == "passed"
    refute Enum.any?(result["issues"], &(&1["severity"] == "error")), inspect(result["issues"])
    assert report["execution_summary"]["accepted_completion_count"] == 1

    Process.put(:motion_artifacts, %{})
    report = Scenario.run!(c.mission, c.study, make_script.([42]), emit)
    a = Process.get(:motion_artifacts)
    child = a["step-01-revised_snapshot.json"]
    # Preserve valid envelope hashes/config binding while replacing the source phase's attitude.
    bad =
      put_in(
        child,
        [
          "payload",
          "inputs",
          "study",
          "saved_motion",
          "assets",
          "demo-3",
          "acquisitions",
          "service",
          "source_plan",
          "phases",
          Access.at(0),
          "quaternion_wxyz"
        ],
        [:math.cos(0.01), 0, 0, :math.sin(0.01)]
      )
      |> F.bind()

    refute Checker.snapshot(bad)["status"] == "failed"
    [row] = report["steps"]

    row =
      row
      |> Map.put("accepted_snapshot_id", bad["snapshot_id"])
      |> put_in(["review", "revised_snapshot_id"], bad["snapshot_id"])

    report = report |> Map.put("final_snapshot_id", bad["snapshot_id"]) |> Map.put("steps", [row])
    a = Map.put(a, "step-01-revised_snapshot.json", bad)

    assert Enum.any?(
             Operations.validate(report, F.load(a))["issues"],
             &(&1["code"] == "advance_inputs_or_ledger")
           )
  end

  test "braking into a later idle hold does not commit the next acquisition or lock tentative demand" do
    alias OrbitalDynamics.MissionAnalysis.PlanRevision.MotionHistory

    root =
      Reference.create!(
        M.load!("studies/rolling_state_reference.json"),
        M.load!("studies/rolling_state_planning.json")
      )

    p =
      Enum.find(
        root["payload"]["report"]["attitude_planning"]["transitions"],
        &(&1["source_epoch_s"] > @epoch)
      )

    brake =
      Enum.find(
        p["phases"],
        &(&1["kind"] == "brake" and &1["ends_after_s"] > &1["starts_after_s"])
      )

    assert brake
    t = p["source_epoch_s"] + brake["ends_after_s"] / 2
    history = MotionHistory.future(root, t)

    assert history["assets"]["demo-3"]["committed"]["ends_at_s"] ==
             p["source_epoch_s"] + brake["ends_after_s"]

    assert MotionHistory.pins(root, t) == []
    refute MotionHistory.committed?(root, @epoch + 200)
  end

  test "a checkpoint between original resource samples preserves original phase clocks and analytic budgets",
       c do
    t = @epoch + 42.125
    replay = Execution.run!(c.root, step(t))
    a = replay.predicted_assets["demo-3"]
    assert_in_delta a["battery_energy_wh"]["battery"], 10 - (38 * 3 + 4.125 * 15) / 3600, 1.0e-8
    assert_in_delta Enum.at(a["angular_velocity_inertial_deg_s"], 2), 0.2 * 4.125, 1.0e-8
    expected_h = 0.001 * 42.125 - 50 * (0.2 * 4.125) * :math.pi() / 180
    assert_in_delta Enum.at(a["wheel_momentum_nms"]["wheels"], 2), expected_h, 1.0e-6
    child = Advance.run!(c.root, replay.update)
    assert child.review["status"] == "ready_for_review"

    same_state(
      Prediction.state_at!(child.revised_snapshot, @epoch + 53)["demo-3"],
      Prediction.state_at!(c.root, @epoch + 53)["demo-3"]
    )
  end

  test "clipped non-principal-axis slews retain original clocks with unequal inertia and a rotated initial attitude",
       c do
    axis = [1, 2, 3] |> Enum.map(&(&1 / :math.sqrt(14)))
    q = [:math.cos(:math.pi() / 9) | Enum.map(axis, &(&1 * :math.sin(:math.pi() / 9)))]

    m =
      update_in(c.mission, ["requests"], fn [r] ->
        [put_in(r, ["parameters", "quaternion_wxyz"], q)]
      end)

    s =
      c.study
      |> put_in(["attitude", "assets", "demo-3", "initial", "quaternion_wxyz"], [
        :math.cos(:math.pi() / 12),
        :math.sin(:math.pi() / 12),
        0,
        0
      ])
      |> put_in(["attitude", "assets", "demo-3", "rigid_body", "principal_moments_kg_m2"], [
        40,
        50,
        60
      ])

    s =
      update_in(s, ["resources", "assets", "demo-3"], fn models ->
        Enum.map(models, fn model ->
          if model["model"] == "reaction_wheels",
            do: put_in(model, ["configuration", "principal_moments_kg_m2"], [40, 50, 60]),
            else: model
        end)
      end)

    root = Reference.create!(m, s)
    [plan] = root["payload"]["report"]["attitude_planning"]["transitions"]
    phase = Enum.find(plan["phases"], &(&1["kind"] == "slew_accelerate"))
    t = plan["source_epoch_s"] + phase["starts_after_s"] + 0.375
    replay = Execution.run!(root, step(t))
    child = Advance.run!(root, replay.update)
    assert child.review["status"] == "ready_for_review", inspect(child.review)

    same_state(
      Prediction.state_at!(child.revised_snapshot, @epoch + 80)["demo-3"],
      Prediction.state_at!(root, @epoch + 80)["demo-3"]
    )
  end
end
