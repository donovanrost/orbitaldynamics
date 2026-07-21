defmodule OrbitalDynamics.CampaignPlanner.RepairReplacementSelection do
  @moduledoc false

  alias OrbitalDynamics.Communications.LinkCapacity
  alias OrbitalDynamics.ResourceProjection

  alias OrbitalDynamics.CampaignPlanner.{
    ActivityIdentity,
    ActivityTiming,
    DownlinkActivityNormalization,
    LinkCapacityPressureBranches,
    RepairActivityIdentity,
    RepairCandidateDiff,
    RepairPolicySemantics,
    ResourceProjectionRisk,
    ScalarValues,
    ValueEncoding
  }

  def candidate(activity, type, acc, context) do
    select(activity, &(&1["type"] == type), type, acc, context)
  end

  def downlink_candidate(activity, acc, context) do
    select(
      activity,
      &DownlinkActivityNormalization.downlink?/1,
      "downlink",
      acc,
      context
    )
  end

  def candidate_diff(source, candidate, context) do
    context
    |> Map.get(:candidate_diff_replacements, %{})
    |> RepairCandidateDiff.replacement_map_rows()
    |> Enum.filter(&candidate_diff_row_matches?(&1, source, candidate))
    |> RepairCandidateDiff.match("source")
  end

  defp select(activity, candidate_filter, intent_type, acc, context) do
    context.candidates
    |> Enum.map(&ValueEncoding.stringify_keys/1)
    |> Enum.reject(&(ActivityIdentity.activity_id(&1) == ActivityIdentity.activity_id(activity)))
    |> Enum.reject(
      &MapSet.member?(context.selected_activity_ids, ActivityIdentity.activity_id(&1))
    )
    |> Enum.reject(&MapSet.member?(acc.used_replacement_ids, ActivityIdentity.activity_id(&1)))
    |> Enum.filter(candidate_filter)
    |> Enum.filter(&ActivityTiming.within_remaining_horizon?(&1, context.remaining_horizon))
    |> Enum.filter(&(ActivityTiming.activity_start(&1) >= context.current_epoch_s))
    |> Enum.reject(
      &RepairPolicySemantics.degraded_incompatible?(
        &1,
        context.degraded_modes,
        context.repair_policy
      )
    )
    |> Enum.reject(
      &MapSet.member?(
        Map.get(context, :rejected_replacement_candidate_ids, MapSet.new()),
        ActivityIdentity.activity_id(&1)
      )
    )
    |> Enum.reject(fn candidate ->
      Enum.any?(acc.activities, &ActivityTiming.overlaps?(candidate, &1))
    end)
    |> Enum.filter(&matches_repair_intent?(activity, &1, intent_type))
    |> reject_duplicate_candidate_ids()
    |> Enum.sort_by(fn candidate ->
      diff_priority =
        case candidate_diff(activity, candidate, context) do
          nil -> 1
          _diff -> 0
        end

      churn_s =
        abs(ActivityTiming.activity_start(candidate) - ActivityTiming.activity_start(activity))

      churn_cost =
        numeric_policy_value(context.scoring_policy, "schedule_churn_cost_weight", 100.0)

      move_cost = numeric_policy_value(context.scoring_policy, "schedule_move_cost_weight", 0.01)

      station_calendar_pressure_penalty =
        station_calendar_pressure_penalty(candidate, context)

      link_capacity_pressure_penalty =
        link_capacity_pressure_penalty(activity, candidate, acc, context)

      resource_projection_pressure_penalty =
        resource_projection_pressure_penalty(activity, candidate, acc, context)

      ranking_score =
        candidate_score(candidate) - churn_cost - churn_s * move_cost -
          station_calendar_pressure_penalty - link_capacity_pressure_penalty -
          resource_projection_pressure_penalty

      {diff_priority, -ranking_score, churn_s, ActivityTiming.activity_start(candidate),
       ActivityIdentity.activity_id(candidate)}
    end)
    |> List.first()
  end

  defp reject_duplicate_candidate_ids(candidates) do
    candidates
    |> Enum.group_by(&ActivityIdentity.activity_id/1)
    |> Enum.flat_map(fn
      {_candidate_id, [candidate]} -> [candidate]
      {_candidate_id, _duplicates} -> []
    end)
  end

  defp candidate_diff_row_matches?(row, source, candidate) do
    source_window_id = RepairActivityIdentity.source_window_id(source)

    row["replacement_candidate_id"] == ActivityIdentity.activity_id(candidate) and
      (row["id"] == ActivityIdentity.activity_id(source) or
         (not is_nil(source_window_id) and row["source_window_id"] == source_window_id))
  end

  defp matches_repair_intent?(source, candidate, "downlink") do
    source_station_id = RepairActivityIdentity.ground_station_id(source)

    ActivityIdentity.same_scenario?(source, candidate) and
      (is_nil(source_station_id) or
         source_station_id == RepairActivityIdentity.ground_station_id(candidate))
  end

  defp matches_repair_intent?(source, candidate, "observe") do
    source["target_id"] == candidate["target_id"]
  end

  defp matches_repair_intent?(_source, _candidate, _type), do: true

  defp candidate_score(candidate),
    do: ScalarValues.numeric_or_nil(Map.get(candidate, "score")) || 0.0

  defp station_calendar_pressure_penalty(candidate, context) do
    pressure_candidate_ids =
      Map.get(context, :station_calendar_pressure_candidate_ids, MapSet.new())

    if MapSet.member?(pressure_candidate_ids, ActivityIdentity.activity_id(candidate)) do
      numeric_policy_value(context.scoring_policy, "risk_weight", 1.0)
    else
      0.0
    end
  end

  defp link_capacity_pressure_penalty(source, candidate, acc, context) do
    projected_activities = projected_activities(source, candidate, acc, context)

    projected_activities
    |> LinkCapacity.report(projected_activities,
      policy: context.link_capacity_policy,
      source: "campaign_repair.replacement_projection"
    )
    |> LinkCapacityPressureBranches.selected_shortfall_pressure?()
    |> then(fn
      true -> numeric_policy_value(context.scoring_policy, "risk_weight", 1.0)
      false -> 0.0
    end)
  end

  defp projected_activities(source, candidate, acc, context) do
    future_planned_activities =
      Enum.filter(
        context.planned_activities,
        &(activity_sort_key(&1) > activity_sort_key(source))
      )

    acc.activities ++ [candidate | future_planned_activities]
  end

  defp resource_projection_pressure_penalty(
         _source,
         _candidate,
         _acc,
         %{source_resource_summaries: []}
       ),
       do: 0.0

  defp resource_projection_pressure_penalty(source, candidate, acc, context) do
    source
    |> projected_activities(candidate, acc, context)
    |> ResourceProjection.report(context.source_resource_summaries,
      model: "thin_repair_replacement_resource_projection",
      source: "source_resource_summaries"
    )
    |> ResourceProjectionRisk.risk_indicators()
    |> length()
    |> Kernel.*(numeric_policy_value(context.scoring_policy, "risk_weight", 1.0))
  end

  defp activity_sort_key(activity) do
    {ActivityTiming.activity_start(activity), ActivityIdentity.activity_id(activity)}
  end

  defp numeric_policy_value(policy, key, default) do
    case ScalarValues.numeric_or_nil(Map.get(policy, key)) do
      value when is_number(value) -> value
      _value -> default
    end
  end
end
