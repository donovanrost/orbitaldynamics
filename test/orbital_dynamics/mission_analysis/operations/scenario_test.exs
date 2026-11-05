defmodule OrbitalDynamics.MissionAnalysis.Operations.ScenarioTest do
  use ExUnit.Case, async: true
  alias OrbitalDynamics.MissionAnalysis.ReferenceMission
  alias OrbitalDynamics.MissionAnalysis.Operations.{Scenario, Report}
  alias OrbitalDynamics.MissionAnalysis.PlanRevision.Snapshot

  @moduletag timeout: 120_000
  setup_all do
    m = ReferenceMission.load!("studies/operations_loop_reference.json")
    s = ReferenceMission.load!("studies/operations_loop_planning.json")
    script = ReferenceMission.load!("studies/operations_loop_scenario.json")
    Process.put(:operations_artifacts, %{})

    emit = fn name, snapshot ->
      a =
        if Map.has_key?(snapshot, "checkpoint_id") do
          assert OrbitalDynamics.MissionAnalysis.PlanRevision.ExecutionCheckpoint.identity!(
                   snapshot
                 ) == snapshot

          snapshot
        else
          assert Snapshot.verify!(snapshot) == snapshot

          %{
            "snapshot_id" => snapshot["snapshot_id"],
            "parent" => snapshot["payload"]["parent_snapshot_id"],
            "inputs" => snapshot["payload"]["inputs"],
            "activities" =>
              snapshot["payload"]["report"]["activities"]
              |> Enum.map(&Map.take(&1, ~w(request_id asset_id starts_at_s ends_at_s protected)))
          }
        end

      Process.put(:operations_artifacts, Map.put(Process.get(:operations_artifacts), name, a))
    end

    report = Scenario.run!(m, s, script, emit)
    {:ok, report: report, artifacts: Process.get(:operations_artifacts)}
  end

  test "multi-cycle execution maintains lifecycle, resources and commitments through scripted perturbations",
       %{report: r, artifacts: artifacts} do
    assert r["verification_status"] == "passed" and r["run_status"] == "completed"

    assert r["execution_summary"] == %{
             "simulated_completion_count" => 4,
             "simulated_completed_value" => 102,
             "scripted_skip_count" => 1,
             "accepted_completion_count" => 4,
             "accepted_expired_count" => 2
           }

    assert length(r["steps"]) == 5

    assert Enum.all?(
             r["steps"],
             &(&1["adopted"] and &1["expectation_met"] and &1["invariant_status"] == "passed")
           )

    assert Enum.all?(r["steps"], fn s -> Enum.all?(s["checks"], & &1["passed"]) end)
    [_, first, outage, restored, last] = r["steps"]
    assert first["state_update"]["completed_request_ids"] == ["early-1", "early-2"]
    assert first["state_update"]["not_executed_request_ids"] == ["early-3"]
    assert first["state_update"]["assets"]["demo-3"]["battery_energy_wh"]["battery"] == 2.5
    assert first["state_update"]["assets"]["demo-3"]["resource_budgets"]["service_tokens"] == 2

    assert first["execution_replay"]["predicted_assets"]["demo-3"]["battery_energy_wh"]["battery"] ==
             10

    assert outage["review"]["service_availability_changes"]["newly_unavailable"] == ["demo-1"]
    assert restored["review"]["service_availability_changes"]["restored"] == ["demo-1"]
    assert outage["accepted_plan"]["scheduled_value"] == 21
    assert restored["accepted_plan"]["scheduled_value"] == 43
    refute Enum.any?(outage["accepted_plan"]["activities"], &(&1["asset_id"] == "demo-1"))
    assert Enum.sort(last["state_update"]["completed_request_ids"]) == ["late-1", "late-2"]
    assert last["accepted_plan"]["activities"] == [] and last["accepted_plan"]["requests"] == []
    closed = r["final_accepted_execution_history"]["closed_requests"]

    assert Enum.sort(for c <- closed, c["status"] == "completed", do: c["request"]["id"]) == [
             "early-1",
             "early-2",
             "late-1",
             "late-2"
           ]

    assert Enum.sort(for c <- closed, c["status"] == "expired", do: c["request"]["id"]) == [
             "early-3",
             "late-3"
           ]

    final = artifacts["step-05-revised_snapshot.json"]["inputs"]

    assert Enum.map(final["mission"]["assets"], & &1["resource_budgets"]["service_tokens"]) == [
             0,
             0,
             2
           ]

    for {id, expected} <- [{"demo-1", 6}, {"demo-2", 6}, {"demo-3", 2.5}] do
      [battery] = final["study"]["resources"]["assets"][id]
      assert_in_delta battery["configuration"]["initial_wh"], expected, 1.0e-10
    end

    assert final["study"]["horizon"]["starts_at_s"] == 820_498_190
    assert final["mission"]["epoch_s"] == 820_497_600
    assert r["execution_epoch_s"] == r["accepted_plan_epoch_s"]
    assert length(Map.keys(artifacts)) == 10

    for name <- ["step-02-execution_snapshot.json", "step-05-execution_snapshot.json"] do
      # Skipped work is absent from the actual execution replay, not just relabeled afterwards.
      refute Enum.any?(artifacts[name]["activities"], &(&1["request_id"] == "early-3"))
    end

    text = r |> Report.markdown() |> IO.iodata_to_binary()
    assert text =~ "Skipped: early-3"
    assert text =~ "early-3: expired"
    assert text =~ "service_outage" and text =~ "second_execution_cycle"
    refute Enum.any?(r["steps"], &Map.has_key?(&1["review"], "planner_timings"))
  end

  defp small do
    {ReferenceMission.load!("studies/rolling_state_reference.json"),
     ReferenceMission.load!("studies/rolling_state_planning.json")}
  end

  defp revision(id, protected, unavailable, expected \\ "ready_for_review"),
    do: %{
      "id" => id,
      "kind" => "revise",
      "expected_status" => expected,
      "change" => %{
        "revision_id" => id,
        "protect_request_ids" => protected,
        "add_requests" => [],
        "unavailable_asset_ids" => unavailable,
        "scheduling" => %{"strategy" => "greedy", "max_trials" => 1}
      }
    }

  defp script(steps),
    do: %{
      "scenario_id" => "test_operations",
      "mission_manifest" => "rolling_state_reference.json",
      "planning_study" => "rolling_state_planning.json",
      "steps" => steps
    }

  test "expected commitment conflict passes its assertion while stopping operations and retaining the last accepted snapshot" do
    {m, s} = small()

    spec =
      script([
        revision("commit", ["late-1"], []),
        revision("outage", [], ["demo-3"], "commitment_conflict")
      ])

    r = Scenario.run!(m, s, spec)
    assert r["verification_status"] == "passed" and r["run_status"] == "stopped_for_review"
    [accepted, refused] = r["steps"]
    assert r["final_snapshot_id"] == accepted["accepted_snapshot_id"]
    assert refused["accepted_snapshot_id"] == accepted["accepted_snapshot_id"]
    refute refused["adopted"]
    assert refused["invariant_status"] == "not_evaluated"
    assert hd(refused["review"]["conflicts"])["placement"]["request_id"] == "late-1"
    assert r["final_accepted_execution_history"] == :null
    assert IO.iodata_to_binary(Report.markdown(r)) =~ "stopped_for_review"
    # An expected failure does not authorize silently skipping later steps.
    unfinished =
      Scenario.run!(m, s, %{spec | "steps" => spec["steps"] ++ [revision("never_run", [], [])]})

    assert unfinished["verification_status"] == "failed"
    assert unfinished["unprocessed_step_ids"] == ["never_run"]
  end

  test "failed post-execution planning keeps the new execution epoch and raw state rather than rolling time back" do
    {m, s} = small()

    step = %{
      "id" => "depleted",
      "kind" => "advance",
      "expected_status" => "unsupported_revision",
      "as_of_s" => 820_497_800,
      "not_executed_request_ids" => [],
      "energy_losses_wh" => %{"demo-3" => %{"battery" => 7}},
      "protect_request_ids" => [],
      "scheduling" => %{"strategy" => "greedy", "max_trials" => 1}
    }

    Process.put(:failed_artifacts, [])

    r =
      Scenario.run!(m, s, script([step]), fn name, _ ->
        Process.put(:failed_artifacts, [name | Process.get(:failed_artifacts)])
      end)

    assert r["verification_status"] == "passed" and r["run_status"] == "stopped_for_review"
    assert r["execution_epoch_s"] == 820_497_800
    assert r["accepted_plan_epoch_s"] == 820_497_600
    assert r["final_snapshot_id"] == r["baseline_snapshot_id"]
    [event] = r["steps"]
    assert event["state_update"]["completed_request_ids"] == ["early-3"]
    assert event["execution_replay"] != :null
    assert event["candidate_report_artifact"] == "step-01-failed_candidate.json"
    assert "step-01-execution_snapshot.json" in Process.get(:failed_artifacts)
    refute "step-01-revised_snapshot.json" in Process.get(:failed_artifacts)
  end

  test "reference scenarios without dynamic resources retain valid empty battery state" do
    {m, study} = small()

    step = %{
      "id" => "no_battery",
      "kind" => "advance",
      "expected_status" => "ready_for_review",
      "as_of_s" => 820_497_800,
      "not_executed_request_ids" => [],
      "energy_losses_wh" => %{},
      "protect_request_ids" => [],
      "scheduling" => %{"strategy" => "greedy", "max_trials" => 1}
    }

    r = Scenario.run!(m, Map.delete(study, "resources"), script([step]))
    assert r["verification_status"] == "passed" and r["run_status"] == "completed"
    assert hd(r["steps"])["state_update"]["assets"]["demo-3"]["battery_energy_wh"] == %{}
  end

  test "semantic report and snapshot identities are deterministic, while invalid scripts and steps fail explicitly" do
    {m, s} = small()
    spec = script([revision("noop", [], [])])
    assert Scenario.run!(m, s, spec) == Scenario.run!(m, s, spec)

    for bad <- [
          Map.put(spec, "steps", []),
          Map.put(spec, "extra", 1),
          %{spec | "steps" => spec["steps"] ++ spec["steps"]},
          %{spec | "steps" => [%{"id" => "x", "kind" => "unknown"}]}
        ] do
      assert_raise ArgumentError, fn -> Scenario.validate!(bad) end
    end

    invalid =
      put_in(spec, ["steps", Access.at(0), "change", "unavailable_asset_ids"], ["unknown_asset"])

    r = Scenario.run!(m, s, invalid)
    assert r["verification_status"] == "failed" and r["run_status"] == "stopped_for_review"
    assert hd(r["steps"])["status"] == "invalid_step"
    assert r["final_snapshot_id"] == r["baseline_snapshot_id"]
  end
end
