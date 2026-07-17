defmodule OrbitalDynamics.CampaignPlanner.RepairReplacementSelection do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    ActivityIdentity,
    ActivityTiming,
    DownlinkActivityNormalization,
    RepairActivityIdentity,
    RepairCandidateDiff,
    RepairPolicySemantics,
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

      {diff_priority, -(candidate_score(candidate) - churn_cost - churn_s * move_cost), churn_s,
       ActivityTiming.activity_start(candidate), ActivityIdentity.activity_id(candidate)}
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

  defp numeric_policy_value(policy, key, default) do
    case ScalarValues.numeric_or_nil(Map.get(policy, key)) do
      value when is_number(value) -> value
      _value -> default
    end
  end
end
