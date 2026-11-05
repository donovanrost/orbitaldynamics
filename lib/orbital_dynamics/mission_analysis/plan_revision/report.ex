defmodule OrbitalDynamics.MissionAnalysis.PlanRevision.Report do
  @moduledoc false
  def markdown(review) do
    boundary =
      if review["execution_update"],
        do:
          "Horizon advanced to #{review["execution_update"]["as_of_s"]} from declared spacecraft state",
        else: "Same horizon and declared initial state"

    header = [
      "# Mission plan revision\n\n",
      "Status: **#{review["status"]}**\n\n",
      "Baseline: `#{review["baseline_snapshot_id"]}`\n\n",
      "Revision: `#{review["revision_id"]}`. #{boundary}. Analysis only; no approval or command execution.\n\n"
    ]

    header =
      header ++
        if review["execution_checkpoint_id"] do
          [
            "Execution checkpoint: `#{review["execution_checkpoint_id"]}` (**accepted**). Plan readiness: `#{review["plan_readiness"]}`. A planning failure does not discard this state.\n\n"
          ]
        else
          []
        end

    header = header ++ execution_summary(review)

    if review["diff"] == :null do
      header ++
        [
          "No revised snapshot was produced.\n\n",
          for(
            c <- review["conflicts"],
            do:
              "- #{c["kind"]}: `#{c["placement"]["request_id"]}` on `#{c["placement"]["asset_id"]}` #{c["reason"] || ""}\n"
          ),
          if(review["planning_error"],
            do:
              "\nPlanning failure category: `#{review["planning_failure_category"] || "planner_error"}`. Error: `#{review["planning_error"]}`\n",
            else: ""
          )
        ]
    else
      d = review["diff"]

      rows =
        for a <- d["activities"],
            do:
              "| #{a["request_id"]} | #{a["change"]} | #{a["protected"]} | #{position(a["before"])} | #{position(a["after"])} |\n"

      header ++
        [
          "Fulfilled value: #{d["baseline_value"]} → #{d["revised_value"]}.\n\n",
          "| Request | Change | Protected | Before: asset / interval | After: asset / interval |\n| --- | --- | --- | --- | --- |\n",
          rows,
          "\n## Unfulfilled requests\n\n",
          for(
            r <- d["unfulfilled_requests"],
            do: [
              "- #{r["request_id"]}: #{Enum.join(r["reasons"], ", ")}\n",
              summary(r["scheduling_summary"])
            ]
          ),
          "\nRemovals and additions are grouped without inferring causal replacement pairs. See revision.json and the revised snapshot for complete inputs and physical evidence.\n"
        ]
    end
  end

  defp execution_summary(%{"execution_update" => update} = review) do
    [
      "State source: `#{update["source_id"]}`. Completed: #{Enum.join(update["completed_request_ids"], ", ")}. Reported not executed: #{Enum.join(update["not_executed_request_ids"], ", ")}.\n\n",
      "Diff values compare future baseline activities with the remaining plan; completed work is excluded.\n\n",
      for(
        row <- review["closed_requests"] || [],
        do: "- Closed #{row["request"]["id"]}: #{row["status"]}\n"
      ),
      for(
        p <- review["missed_past_commitments"] || [],
        do: "- Missed past commitment: #{p["request_id"]}\n"
      ),
      "\n"
    ]
  end

  defp execution_summary(_), do: []

  defp summary(s) when is_map(s) do
    reasons =
      s["attempt_reasons"] |> Enum.sort() |> Enum.map_join(", ", fn {r, n} -> "#{r}=#{n}" end)

    rules =
      s["constraint_issues"]
      |> Enum.map(&(&1["rule_id"] || &1["model_id"] || &1["reason"]))
      |> Enum.uniq()
      |> Enum.sort()
      |> Enum.join(", ")

    "  Tested starts: #{s["tested_start_count"]}; failures: #{reasons}; checks: #{rules}; start cap reached: #{s["start_search_truncated"]}; unknown placements: #{s["unknown_placement_count"]}; search: #{s["search_status"]}.\n"
  end

  defp summary(_), do: ""

  defp position(:null), do: "—"
  defp position(p), do: "#{p["asset_id"]} / #{p["starts_at_s"]}–#{p["ends_at_s"]}"
end
