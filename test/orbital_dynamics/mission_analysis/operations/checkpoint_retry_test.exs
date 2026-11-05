defmodule OrbitalDynamics.MissionAnalysis.Operations.CheckpointRetryTest do
  use ExUnit.Case, async: true
  alias OrbitalDynamics.MissionAnalysis.ReferenceMission, as: M
  alias OrbitalDynamics.MissionAnalysis.Operations.Scenario
  alias OrbitalDynamics.MissionAnalysis.PlanValidation.Operations
  alias OrbitalDynamics.IndependentPlanFixture, as: F
  @t 820_497_600
  defp advance(id, t, budget, status),
    do: %{
      "id" => id,
      "kind" => "advance",
      "expected_status" => status,
      "as_of_s" => @t + t,
      "not_executed_request_ids" => [],
      "energy_losses_wh" => %{},
      "protect_request_ids" => [],
      "scheduling" => %{
        "strategy" => "greedy",
        "max_trials" => 1,
        "work_budget" => %{"max_evaluations" => budget}
      }
    }

  defp retry(id, budget, status),
    do: %{
      "id" => id,
      "kind" => "retry",
      "expected_status" => status,
      "scheduling" => %{
        "strategy" => "greedy",
        "max_trials" => 1,
        "work_budget" => %{"max_evaluations" => budget}
      }
    }

  defp run(m, s, steps) do
    Process.put(:checkpoint_files, %{})
    Process.put(:emit_order, [])

    script = %{
      "scenario_id" => "checkpoint_retry",
      "mission_manifest" => "synthetic.json",
      "planning_study" => "synthetic.json",
      "steps" => steps
    }

    r =
      Scenario.run!(m, s, script, fn name, v ->
        Process.put(:checkpoint_files, Map.put(Process.get(:checkpoint_files), name, v))
        Process.put(:emit_order, Process.get(:emit_order) ++ [name])
      end)

    {r, Process.get(:checkpoint_files)}
  end

  setup do
    {:ok,
     mission: M.load!("studies/thermal_cooldown_reference.json"),
     study: M.load!("studies/thermal_cooldown_planning.json")}
  end

  test "repeated failed and successful attempts reuse one accepted in-progress execution checkpoint",
       c do
    {r, a} =
      run(c.mission, c.study, [
        advance("limited", 75, 1, "planning_failed"),
        retry("still_limited", 1, "planning_failed"),
        retry("larger_budget", 100_000, "ready_for_review"),
        advance("finish", 90, 100_000, "ready_for_review")
      ])

    assert r["verification_status"] == "passed"
    assert r["run_status"] == "completed"
    [first, again, success, last] = r["steps"]

    assert first["execution_checkpoint_id"] == again["execution_checkpoint_id"] and
             again["execution_checkpoint_id"] == success["execution_checkpoint_id"]

    for row <- [again, success] do
      assert row["state_update"] == :null and row["execution_replay"] == :null
      assert row["executed_services"] == []
      assert row["execution_epoch_s"] == first["execution_epoch_s"]
      refute row["execution_checkpoint_accepted"]
    end

    cp = a["step-01-execution_checkpoint.json"]
    child = a["step-03-revised_snapshot.json"]
    assert child["payload"]["inputs"]["execution"] == cp["payload"]["inputs"]["execution"]

    assert child["payload"]["inputs"]["mission"]["assets"] ==
             cp["payload"]["inputs"]["mission"]["assets"]

    assert last["execution_checkpoint_id"] != first["execution_checkpoint_id"]
    assert r["execution_summary"]["accepted_completion_count"] == 2
    assert r["execution_summary"]["simulated_completion_count"] == 2
    assert r["execution_summary"]["simulated_completed_value"] == 10
    assert Operations.validate(r, F.load(a))["status"] == "passed"
    order = Process.get(:emit_order)

    assert Enum.find_index(order, &(&1 == "step-01-execution_checkpoint.json")) <
             Enum.find_index(order, &(&1 == "step-03-revised_snapshot.json"))
  end

  test "committed acquisition and delivered command receipts survive failed planning", _c do
    m = M.load!("studies/motion_checkpoint_reference.json")
    s = M.load!("studies/motion_checkpoint_planning.json")
    commands = M.load!("studies/command_delivery_planning.json")["scheduling"]["command_delivery"]

    commands =
      commands
      |> put_in(["contacts", Access.at(0), "starts_at_s"], @t + 10)
      |> put_in(["contacts", Access.at(0), "ends_at_s"], @t + 14)
      |> put_in(["requirements", Access.at(0), "minimum_contact_duration_s"], 4)

    s = put_in(s, ["scheduling", "command_delivery"], commands)

    {r, a} =
      run(m, s, [
        advance("during_acquisition", 53, 1, "planning_failed"),
        retry("retry", 100_000, "ready_for_review")
      ])

    assert r["verification_status"] == "passed"
    cp = a["step-01-execution_checkpoint.json"]["payload"]["inputs"]
    child = a["step-02-revised_snapshot.json"]["payload"]["inputs"]
    assert child["study"]["saved_motion"] == cp["study"]["saved_motion"]

    assert child["study"]["scheduling"]["protected_activities"] ==
             cp["study"]["scheduling"]["protected_activities"]

    assert child["study"]["scheduling"]["command_delivery"]["receipts"] ==
             cp["study"]["scheduling"]["command_delivery"]["receipts"]

    assert length(child["study"]["scheduling"]["command_delivery"]["receipts"]) == 1
    assert Operations.validate(r, F.load(a))["status"] == "passed"
  end

  test "a failed plan retains accepted execution history and blocks execution from the stale plan",
       c do
    {r, a} = run(c.mission, c.study, [advance("limited", 90, 1, "planning_failed")])
    assert r["verification_status"] == "passed"
    assert r["run_status"] == "stopped_for_review"
    assert r["plan_readiness"] == "stale_pending_replan"
    assert r["execution_epoch_s"] == @t + 90 and r["accepted_plan_epoch_s"] == @t
    assert r["execution_summary"]["accepted_completion_count"] == 2
    assert r["final_plan_bound_execution_history"] == :null

    assert r["final_accepted_execution_history"] ==
             a["step-01-execution_checkpoint.json"]["payload"]["inputs"]["execution"]

    assert Operations.validate(r, F.load(a))["status"] == "partial"

    {blocked, files} =
      run(c.mission, c.study, [
        advance("limited", 75, 1, "planning_failed"),
        advance("must_not_execute", 90, 100_000, "ready_for_review")
      ])

    assert blocked["unprocessed_step_ids"] == ["must_not_execute"]
    assert length(blocked["steps"]) == 1
    refute Map.has_key?(files, "step-02-execution_snapshot.json")

    {invalid, files} =
      run(c.mission, c.study, [retry("without_checkpoint", 1000, "invalid_step")])

    assert invalid["verification_status"] == "passed"
    assert invalid["latest_execution_checkpoint_id"] == :null
    checked = Operations.validate(invalid, F.load(files))
    assert checked["status"] == "partial"
    refute Enum.any?(checked["issues"], &(&1["severity"] == "error"))
  end

  test "independent checking detects a coherently rehashed checkpoint mutation", c do
    {r, a} =
      run(c.mission, c.study, [
        advance("limited", 75, 1, "planning_failed"),
        retry("retry", 100_000, "ready_for_review")
      ])

    cp =
      a["step-01-execution_checkpoint.json"]
      |> put_in(
        [
          "payload",
          "inputs",
          "mission",
          "assets",
          Access.at(0),
          "resource_budgets",
          "service_tokens"
        ],
        1
      )

    hash = OrbitalDynamics.MissionAnalysis.PlanValidation.Checker.digest(cp["payload"])

    cp =
      cp
      |> Map.put("content_sha256", hash)
      |> Map.put("checkpoint_id", "mission_execution_checkpoint:" <> hash)

    a = Map.put(a, "step-01-execution_checkpoint.json", cp)
    checked = Operations.validate(r, F.load(a))
    assert checked["status"] == "failed"
    assert Enum.any?(checked["issues"], &(&1["code"] == "execution_checkpoint_state"))
  end
end
