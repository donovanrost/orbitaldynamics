defmodule OrbitalDynamics.MissionAnalysis.Operations.Report do
  @moduledoc false
  def markdown(r) do
    [
      "# Scripted operations review\n\nScenario: `#{r["scenario_id"]}`. Verification: **#{r["verification_status"]}**. Run: **#{r["run_status"]}**.\n\n",
      "Synthetic execution and replanning only; no telemetry or command execution. Epochs are UTC seconds since J2000.\n\n",
      "Last accepted planning boundary: #{r["accepted_plan_epoch_s"]}. Accepted execution epoch: #{r["accepted_execution_epoch_s"]}. Simulated execution epoch: #{r["execution_epoch_s"]}. A stopped run requires review before further execution.\n\n",
      "Plan readiness: `#{r["plan_readiness"]}`. Latest accepted execution checkpoint: `#{r["latest_execution_checkpoint_id"]}`.\n\n",
      "Simulated completions: #{r["execution_summary"]["simulated_completion_count"]}, value #{r["execution_summary"]["simulated_completed_value"]}. Scripted skips: #{r["execution_summary"]["scripted_skip_count"]}. Completions in the accepted ledger: #{r["execution_summary"]["accepted_completion_count"]}.\n\n",
      "Baseline: `#{r["baseline_snapshot_id"]}` ([snapshot](baseline_snapshot.json)).\n\n",
      "| Step | Kind | Execution epoch | Result | Adopted | Stored plan value |\n| --- | --- | --- | --- | --- | --- |\n",
      for(
        s <- r["steps"],
        do:
          "| #{s["id"]} | #{s["kind"]} | #{s["execution_epoch_s"]} | #{s["status"]} | #{s["adopted"]} | #{s["accepted_plan"]["scheduled_value"]} |\n"
      ),
      "\nValues belong to the referenced accepted plan. When its readiness is stale_pending_replan, they are not a current executable forecast.\n\n",
      for(s <- r["steps"], do: step(s)),
      "## Accepted execution history\n\n",
      for(
        c <- closed(r),
        do: "- #{c["request"]["id"]}: #{c["status"]} at #{c["reported_at_s"]}\n"
      ),
      "\n## Limits\n\n",
      for(l <- r["limits"], do: "- #{l}\n"),
      "\nFull changes, state updates, invariant results and request explanations are in operations.json. Accepted snapshots and execution replay snapshots are saved separately.\n"
    ]
  end

  defp step(s) do
    review = s["review"]
    update = s["state_update"]

    [
      "## #{s["index"]}. #{s["id"]}\n\nExpected: #{s["expected_status"]}; observed: #{s["status"]}. Invariant checks: #{Enum.count(s["checks"], & &1["passed"])}/#{length(s["checks"])}.\n\n",
      if(s["execution_checkpoint_id"] != :null,
        do:
          "Execution checkpoint: `#{s["execution_checkpoint_id"]}` ([artifact](#{s["execution_checkpoint_artifact"]})). Accepted this step: #{s["execution_checkpoint_accepted"]}. Plan readiness: `#{s["plan_readiness"]}`.\n\n",
        else: ""
      ),
      if(update != :null,
        do: [
          "Executed: #{ids(update["completed_request_ids"])}. Skipped: #{ids(update["not_executed_request_ids"])}.\n\n",
          "Replay policy: `#{s["execution_replay"]["policy"]}`.\n\n",
          if(Map.get(update, "in_progress_request_ids", []) == [],
            do: [],
            else:
              "In progress, reserved to the original end: #{ids(update["in_progress_request_ids"])}.\n\n"
          ),
          for(
            {id, a} <- Enum.sort(update["assets"]),
            do:
              "- #{id}: battery Wh #{pairs(a["battery_energy_wh"])}; remaining static budgets #{pairs(a["resource_budgets"])}#{wheel_state(a)}#{thermal_state(a)}\n"
          ),
          "\n"
        ],
        else: ""
      ),
      if(is_map(review["service_availability_changes"]),
        do:
          "Service newly unavailable: #{ids(review["service_availability_changes"]["newly_unavailable"])}. Restored: #{ids(review["service_availability_changes"]["restored"])}.\n\n",
        else: ""
      ),
      if(is_map(review["diff"]),
        do: [
          "Future value: #{review["diff"]["baseline_value"]} → #{review["diff"]["revised_value"]}.\n\n",
          for(
            a <- review["diff"]["activities"],
            a["change"] != "unchanged",
            do: "- #{a["request_id"]}: #{a["change"]}\n"
          ),
          "\n"
        ],
        else: ""
      ),
      for(
        c <- review["conflicts"] || [],
        do: "- Conflict: #{c["kind"]} / #{get_in(c, ["placement", "request_id"])}\n"
      ),
      if(review["error"] || review["planning_error"],
        do: "Issue: #{review["error"] || review["planning_error"]}\n\n",
        else: ""
      ),
      for(
        e <- s["unfulfilled_explanations"],
        do:
          "- Unfulfilled #{e["request_id"]}: #{Enum.join(e["reasons"], ", ")}; tested starts #{e["summary"]["tested_start_count"]}; search #{e["summary"]["search_status"]}\n"
      ),
      "\n"
    ]
  end

  defp thermal_state(%{"thermal_temperature_k" => nodes}), do: "; temperature K " <> pairs(nodes)
  defp thermal_state(_), do: ""

  defp wheel_state(%{"wheel_momentum_nms" => arrays}),
    do:
      "; wheel momentum Nms " <>
        Enum.map_join(Enum.sort(arrays), ", ", fn {id, h} ->
          "#{id}=[#{Enum.map_join(h, ", ", &Float.to_string(&1 * 1.0))}]"
        end)

  defp wheel_state(_), do: ""

  defp pairs(m),
    do:
      m
      |> Enum.sort()
      |> Enum.map_join(", ", fn {id, value} -> "#{id}=#{Float.round(value * 1.0, 6)}" end)

  defp closed(%{"final_accepted_execution_history" => history}) when is_map(history),
    do: history["closed_requests"]

  defp closed(_), do: []
  defp ids([]), do: "none"
  defp ids(ids), do: Enum.join(ids, ", ")
end
