defmodule OrbitalDynamics.MissionAnalysis.PlanRevision.ContinuationTest do
  use ExUnit.Case, async: true
  alias OrbitalDynamics.MissionAnalysis.{ReferenceMission, ReactionWheelQualityCases}
  alias OrbitalDynamics.MissionAnalysis.PlanRevision.{Reference, Prediction, Advance}
  alias OrbitalDynamics.MissionAnalysis.PlanValidation.{Checker, Operations}
  alias OrbitalDynamics.MissionAnalysis.Operations.{Scenario, Execution}
  alias OrbitalDynamics.IndependentPlanFixture, as: F

  defp step(id, t),
    do: %{
      "id" => id,
      "kind" => "advance",
      "expected_status" => "ready_for_review",
      "as_of_s" => t,
      "not_executed_request_ids" => [],
      "energy_losses_wh" => %{},
      "protect_request_ids" => [],
      "scheduling" => %{"strategy" => "greedy", "max_trials" => 1}
    }

  setup_all do
    m = ReferenceMission.load!("studies/automatic_wheel_maintenance.json")
    s = ReferenceMission.load!("studies/automatic_wheel_maintenance_planning.json")
    snapshot = Reference.create!(m, s)
    {:ok, mission: m, study: s, snapshot: snapshot}
  end

  test "repeated checkpoints preserve original identity and charge the activity once", ctx do
    a = Advance.run!(ctx.snapshot, Prediction.update!(ctx.snapshot, 820_497_625))
    assert a.review["status"] == "ready_for_review"
    first = a.revised_snapshot
    row = first["payload"]["inputs"]["study"]["continuations"]["unload"]
    assert row["request"]["duration_s"] == 20
    assert row["baseline_activity"]["starts_at_s"] == 820_497_620
    assert hd(first["payload"]["inputs"]["mission"]["requests"])["duration_s"] == 15

    assert first["payload"]["inputs"]["mission"]["assets"]
           |> hd()
           |> get_in(["resource_budgets", "unload_tokens"]) == 0

    b = Advance.run!(first, Prediction.update!(first, 820_497_630))
    assert b.review["status"] == "ready_for_review"
    second = b.revised_snapshot
    assert second["payload"]["inputs"]["study"]["continuations"]["unload"] == row

    assert Enum.find(b.candidate_report["activities"], &(&1["request_id"] == "unload"))[
             "resource_costs"
           ] == %{}

    c = Advance.run!(second, Prediction.update!(second, 820_497_660))
    assert c.review["status"] == "ready_for_review"
    source = Reference.source!(c.revised_snapshot)
    refute Map.has_key?(source["study"], "continuations")
    [closed] = source["execution"]["closed_requests"]

    assert closed["request"]["duration_s"] == 20 and
             closed["request"]["resource_costs"]["unload_tokens"] == 1

    assert closed["baseline_activity"]["starts_at_s"] == 820_497_620 and
             closed["baseline_activity"]["ends_at_s"] == 820_497_640
  end

  test "prefix replay does not complete a running activity or force an early terminal return",
       ctx do
    replay = Execution.run!(ctx.snapshot, step("inside", 820_497_625))
    assert replay.update["completed_request_ids"] == []
    assert replay.update["in_progress_request_ids"] == ["unload"]

    assert_in_delta replay.update["assets"]["demo-3"]["battery_energy_wh"]["battery"],
                    10 - 12 * 5 / 3600,
                    1.0e-8

    assert_in_delta Enum.at(replay.update["assets"]["demo-3"]["wheel_momentum_nms"]["wheels"], 2),
                    0.225,
                    1.0e-8

    request = hd(replay.snapshot["payload"]["inputs"]["mission"]["requests"])
    assert request["duration_s"] == 5 and request["value"] == 0
    assert Checker.snapshot(replay.snapshot)["status"] == "passed"
  end

  test "missing running confirmation, incompatible pose, skipping or calendar conflicts cannot silently replace running work",
       ctx do
    u = Prediction.update!(ctx.snapshot, 820_497_625)

    r =
      Advance.run!(ctx.snapshot, Map.delete(u, "in_progress_request_ids"), fn _, _, _ ->
        flunk("unconfirmed continuation reached planner")
      end)

    assert r.review["status"] == "in_progress_state_incomplete" and r.revised_snapshot == :null
    wrong = put_in(u, ["assets", "demo-3", "quaternion_wxyz"], [0, 0, 0, 1])
    assert Advance.run!(ctx.snapshot, wrong).review["status"] == "commitment_conflict"
    running = Advance.run!(ctx.snapshot, u).revised_snapshot

    late =
      Prediction.update!(running, 820_497_660)
      |> Map.put("completed_request_ids", [])
      |> Map.put("not_executed_request_ids", ["unload"])

    assert_raise ArgumentError, fn -> Advance.run!(running, late) end

    assert_raise ArgumentError, fn ->
      Execution.run!(running, %{
        step("skip", 820_497_660)
        | "not_executed_request_ids" => ["unload"]
      })
    end

    cal = %{
      "time_scale" => "utc",
      "outages" => [
        %{
          "id" => "failure",
          "asset_id" => "demo-3",
          "starts_at_s" => 820_497_626,
          "ends_at_s" => 820_497_635,
          "scope" => %{"kind" => "modes", "ids" => ["desaturate"]}
        }
      ]
    }

    change = %{
      "revision_id" => "cannot_abort",
      "protect_request_ids" => [],
      "add_requests" => [],
      "unavailable_asset_ids" => [],
      "scheduling" => %{"strategy" => "greedy", "max_trials" => 1, "availability" => cal}
    }

    conflict = Reference.revise!(running, change)

    assert conflict.review["status"] == "commitment_conflict" and
             conflict.revised_snapshot == :null
  end

  test "execution and independent checking agree through repeated checkpoints and exact completion boundaries",
       ctx do
    script =
      ReferenceMission.load!("studies/automatic_wheel_maintenance_operations.json")
      |> Map.put("steps", [
        step("unload_started", 820_497_625),
        step("unload_still_running", 820_497_630),
        step("unload_completed", 820_497_640),
        step("service_started", 820_497_675),
        step("service_completed", 820_497_680)
      ])

    Process.put(:continuation_files, %{})

    r =
      Scenario.run!(ctx.mission, ctx.study, script, fn name, v ->
        Process.put(:continuation_files, Map.put(Process.get(:continuation_files), name, v))
      end)

    assert r["verification_status"] == "passed" and r["run_status"] == "completed"

    assert r["execution_summary"]["accepted_completion_count"] == 2 and
             r["execution_summary"]["simulated_completed_value"] == 10

    assert Operations.validate(r, F.load(Process.get(:continuation_files)))["status"] == "passed"
  end

  test "coherently rehashed original-cost tampering passes alone but fails parent-derived continuation history",
       ctx do
    script =
      ReferenceMission.load!("studies/automatic_wheel_maintenance_operations.json")
      |> Map.put("steps", [step("inside", 820_497_625)])

    Process.put(:continuation_mutation_files, %{})

    report =
      Scenario.run!(ctx.mission, ctx.study, script, fn name, value ->
        Process.put(
          :continuation_mutation_files,
          Map.put(Process.get(:continuation_mutation_files), name, value)
        )
      end)

    files = Process.get(:continuation_mutation_files)

    child =
      files["step-01-revised_snapshot.json"]
      |> put_in(
        [
          "payload",
          "inputs",
          "study",
          "continuations",
          "unload",
          "request",
          "resource_costs",
          "unload_tokens"
        ],
        2
      )
      |> update_in(["payload", "report", "activities"], fn acts ->
        Enum.map(acts, fn a ->
          if a["request_id"] == "unload",
            do: put_in(a, ["activity_segment", "original_resource_costs", "unload_tokens"], 2),
            else: a
        end)
      end)
      |> update_in(["payload", "report", "requests"], fn requests ->
        Enum.map(requests, fn r ->
          if r["request_id"] == "unload",
            do: put_in(r, ["activity_segment", "original_resource_costs", "unload_tokens"], 2),
            else: r
        end)
      end)
      |> F.bind()

    assert Checker.snapshot(child)["status"] == "passed"

    report =
      report
      |> Map.put("final_snapshot_id", child["snapshot_id"])
      |> put_in(["steps", Access.at(0), "accepted_snapshot_id"], child["snapshot_id"])
      |> put_in(["steps", Access.at(0), "review", "revised_snapshot_id"], child["snapshot_id"])

    result =
      Operations.validate(report, F.load(Map.put(files, "step-01-revised_snapshot.json", child)))

    assert result["status"] == "failed"
    assert Enum.any?(result["issues"], &(&1["code"] == "advance_inputs_or_ledger"))
  end

  test "a rotating acquisition prefix remains intact while a service continues in its fixed attitude" do
    {m, s} = ReactionWheelQualityCases.inputs("feasible_slew")
    snapshot = Reference.create!(m, s)
    replay = Execution.run!(snapshot, step("slew_then_service", m["epoch_s"] + 105))
    assert replay.update["in_progress_request_ids"] == ["service"]

    assert_in_delta replay.update["assets"]["demo-3"]["battery_energy_wh"]["battery"],
                    10 - 2 * 5 / 3600,
                    1.0e-8

    a = Advance.run!(snapshot, replay.update)
    assert a.review["status"] == "ready_for_review"
    assert hd(a.candidate_report["activities"])["ends_at_s"] == m["epoch_s"] + 110

    b =
      Advance.run!(a.revised_snapshot, Prediction.update!(a.revised_snapshot, m["epoch_s"] + 160))

    assert b.review["status"] == "ready_for_review"

    assert hd(b.revised_snapshot["payload"]["inputs"]["execution"]["closed_requests"])["request"][
             "duration_s"
           ] == 10
  end

  test "nonzero-rate illumination tracking can continue at a saved attitude sample" do
    m = ReferenceMission.load!("studies/rolling_state_reference.json")

    s =
      ReferenceMission.load!("studies/rolling_state_planning.json")
      |> put_in(["attitude", "profile_step_s"], 1)

    snapshot = Reference.create!(m, s)
    early = hd(snapshot["payload"]["report"]["activities"])
    t = early["starts_at_s"] + 5
    replay = Execution.run!(snapshot, step("tracking", t))

    assert Enum.any?(
             replay.update["assets"][early["asset_id"]]["angular_velocity_inertial_deg_s"],
             &(abs(&1) > 1.0e-4)
           )

    result = Advance.run!(snapshot, replay.update)
    assert result.review["status"] == "ready_for_review"

    tail =
      Enum.find(result.candidate_report["activities"], &(&1["request_id"] == early["request_id"]))

    assert tail["starts_at_s"] == t and tail["ends_at_s"] == early["ends_at_s"]
  end
end
