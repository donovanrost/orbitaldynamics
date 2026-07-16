defmodule OrbitalDynamics.CampaignPlanner.StrategyRiskIndicators do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    CandidateSourceReplayRisk,
    DownlinkActivityNormalization,
    EventRiskIndicator,
    PriorityCommitmentSatisfaction,
    ValueEncoding,
    ResourceProjectionRisk
  }

  def build(
        branch,
        repair_result,
        candidate_plan,
        request,
        resource_impacts,
        resource_projection_report,
        feedback_adjustments,
        candidate_source
      ) do
    build(
      branch,
      repair_result,
      candidate_plan,
      request,
      resource_impacts,
      resource_projection_report,
      feedback_adjustments,
      candidate_source,
      default_callbacks()
    )
  end

  def build(
        branch,
        repair_result,
        candidate_plan,
        request,
        resource_impacts,
        resource_projection_report,
        feedback_adjustments,
        candidate_source,
        callbacks
      ) do
    event_risks =
      branch["events"]
      |> Enum.flat_map(&event_risk_indicators/1)

    warning_risks =
      repair_result
      |> Map.get("warnings", [])
      |> Enum.map(fn warning ->
        %{"type" => "repair_warning", "severity" => "medium", "reason" => warning}
      end)

    objective_risks = objective_risks(candidate_plan, request, callbacks)
    resource_risks = Map.get(resource_impacts, "risk_indicators", [])
    resource_projection_risks = ResourceProjectionRisk.risk_indicators(resource_projection_report)
    feedback_risks = Map.get(feedback_adjustments, "risk_indicators", [])

    candidate_source_risks =
      candidate_source_risk_indicators(candidate_source, branch, event_risks)

    feasibility_risks = feasibility_risks(candidate_plan, callbacks)

    (event_risks ++
       warning_risks ++
       objective_risks ++
       resource_risks ++
       resource_projection_risks ++
       feedback_risks ++
       candidate_source_risks ++
       feasibility_risks)
    |> Enum.uniq()
    |> Enum.sort_by(&{&1["severity"], &1["type"], &1["reason"]})
  end

  defp objective_risks(candidate_plan, request, callbacks) do
    []
    |> maybe_add_no_downlink_risk(candidate_plan, request, callbacks)
    |> maybe_add_unmet_priority_commitment_risk(candidate_plan, request, callbacks)
  end

  defp maybe_add_no_downlink_risk(risks, candidate_plan, request, callbacks) do
    downlink_activity? = Keyword.fetch!(callbacks, :downlink_activity?)

    requires_downlink? =
      request.mission_state
      |> Map.get("objectives", [])
      |> Enum.any?(&(Map.get(&1, "type") == "downlink_completion"))

    has_downlink? = Enum.any?(candidate_plan["activities"], downlink_activity?)

    if requires_downlink? and not has_downlink? do
      [
        %{
          "type" => "no_viable_downlink",
          "severity" => "high",
          "reason" => "branch has no downlink activity"
        }
        | risks
      ]
    else
      risks
    end
  end

  defp maybe_add_unmet_priority_commitment_risk(risks, candidate_plan, request, callbacks) do
    priority_commitment_satisfaction_rows =
      Keyword.fetch!(callbacks, :priority_commitment_satisfaction_rows)

    compact_map = Keyword.fetch!(callbacks, :compact_map)

    request.mission_state
    |> priority_commitment_satisfaction_rows.(Map.get(candidate_plan, "activities", []))
    |> Enum.reject(&(&1["status"] == "satisfied"))
    |> Enum.reduce(risks, fn row, acc ->
      [
        %{
          "type" => "priority_commitment_unmet",
          "severity" => "medium",
          "reason" =>
            "target #{row["target_id"]} planned observations #{row["planned_observations"]} below required #{row["required_observations"]}",
          "target_id" => row["target_id"],
          "objective_id" => row["objective_id"],
          "required_observations" => row["required_observations"],
          "planned_observations" => row["planned_observations"],
          "missing_observations" => row["missing_observations"]
        }
        |> compact_map.()
        | acc
      ]
    end)
  end

  defp feasibility_risks(candidate_plan, callbacks) do
    compact_map = Keyword.fetch!(callbacks, :compact_map)

    candidate_plan
    |> Map.get("strategic_additions", [])
    |> Enum.filter(&(get_in(&1, ["feasibility", "status"]) == "unvalidated_placeholder"))
    |> Enum.map(fn activity ->
      %{
        "type" => "urgent_target_unvalidated",
        "severity" => "medium",
        "reason" => "urgent target #{activity["target_id"]} has no validated candidate window",
        "target_id" => activity["target_id"]
      }
      |> compact_map.()
    end)
  end

  defp candidate_source_risk_indicators(candidate_source, branch, event_risks) do
    if branch["events"] in [nil, []] do
      []
    else
      candidate_source_risk_indicators(candidate_source, event_risks)
    end
  end

  defp candidate_source_risk_indicators(candidate_source, event_risks),
    do: CandidateSourceReplayRisk.indicators(candidate_source, event_risks)

  defp event_risk_indicators(event), do: EventRiskIndicator.indicators(event)

  defp default_callbacks,
    do: [
      downlink_activity?: &DownlinkActivityNormalization.downlink?/1,
      priority_commitment_satisfaction_rows: &priority_commitment_satisfaction_rows/2,
      compact_map: &ValueEncoding.compact_map/1
    ]

  defp priority_commitment_satisfaction_rows(mission_state, activities) do
    mission_state
    |> PriorityCommitmentSatisfaction.objectives()
    |> PriorityCommitmentSatisfaction.rows(activities)
  end
end
