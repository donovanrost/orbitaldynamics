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
    |> Enum.map(&ranked_candidate(activity, &1, acc, context))
    |> Enum.sort_by(& &1.sort_key)
    |> selected_candidate()
  end

  defp ranked_candidate(source, candidate, acc, context) do
    semantic_candidate_diff_match = not is_nil(candidate_diff(source, candidate, context))
    diff_priority = if semantic_candidate_diff_match, do: 0, else: 1

    churn_s =
      abs(ActivityTiming.activity_start(candidate) - ActivityTiming.activity_start(source))

    churn_cost =
      numeric_policy_value(context.scoring_policy, "schedule_churn_cost_weight", 100.0)

    move_cost = numeric_policy_value(context.scoring_policy, "schedule_move_cost_weight", 0.01)
    station_pressure_sources = station_calendar_pressure_sources(candidate, context)
    station_pressure = station_calendar_pressure_penalty(station_pressure_sources, context)
    contact_intent_pressure_statuses = contact_intent_pressure_statuses(candidate, context)

    contact_intent_pressure =
      contact_intent_pressure_penalty(contact_intent_pressure_statuses, context)

    contact_contention_resolution_group_ids =
      contact_contention_resolution_group_ids(candidate, context)

    contact_contention_resolution_pressure =
      contact_contention_resolution_pressure_penalty(
        contact_contention_resolution_group_ids,
        context
      )

    link_pressure = link_capacity_pressure(source, candidate, acc, context)
    resource_pressure = resource_projection_pressure(source, candidate, acc, context)

    ranking_score =
      candidate_score(candidate) - churn_cost - churn_s * move_cost - station_pressure -
        contact_intent_pressure - contact_contention_resolution_pressure -
        link_pressure.penalty - resource_pressure.penalty

    row =
      %{
        "candidate_id" => ActivityIdentity.activity_id(candidate),
        "semantic_candidate_diff_match" => semantic_candidate_diff_match,
        "candidate_diff_priority" => diff_priority,
        "candidate_score" => candidate_score(candidate),
        "schedule_churn_s" => churn_s,
        "schedule_churn_penalty" => -churn_cost,
        "schedule_move_penalty" => -(churn_s * move_cost),
        "station_calendar_pressure_penalty" => negative_penalty(station_pressure),
        "contact_intent_pressure_penalty" => negative_penalty(contact_intent_pressure),
        "contact_contention_resolution_pressure_penalty" =>
          negative_penalty(contact_contention_resolution_pressure),
        "link_capacity_pressure_penalty" => negative_penalty(link_pressure.penalty),
        "resource_projection_pressure_penalty" => negative_penalty(resource_pressure.penalty),
        "ranking_score" => ranking_score
      }
      |> maybe_put_nonempty(
        "station_calendar_pressure_sources",
        station_pressure_sources
      )
      |> maybe_put_nonempty(
        "contact_intent_pressure_statuses",
        contact_intent_pressure_statuses
      )
      |> maybe_put_nonempty(
        "contact_contention_resolution_group_ids",
        contact_contention_resolution_group_ids
      )
      |> maybe_put_non_nil(
        "link_capacity_pressure_shortfall_mb",
        link_pressure.shortfall_mb
      )
      |> maybe_put_nonempty(
        "resource_projection_pressure_risk_indicators",
        resource_pressure.risk_indicators
      )

    %{
      candidate: candidate,
      sort_key:
        {diff_priority, -ranking_score, churn_s, ActivityTiming.activity_start(candidate),
         ActivityIdentity.activity_id(candidate)},
      row: row
    }
  end

  defp selected_candidate([]), do: nil

  defp selected_candidate([selected | _rest] = ranked_candidates) do
    selected_candidate_id = ActivityIdentity.activity_id(selected.candidate)

    rows =
      ranked_candidates
      |> Enum.with_index(1)
      |> Enum.map(fn {ranked, rank} ->
        ranked.row
        |> Map.put("rank", rank)
        |> Map.put("selected", ranked.row["candidate_id"] == selected_candidate_id)
      end)

    %{
      candidate: selected.candidate,
      ranking: %{
        "model" => "greedy_repair_replacement_ranking",
        "selection_scope" => "viable_unique_candidates_within_repair_intent",
        "selected_candidate_id" => selected_candidate_id,
        "evaluated_candidate_count" => length(rows),
        "rows" => rows,
        "global_optimization" => false
      }
    }
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

  defp station_calendar_pressure_sources(candidate, context) do
    context
    |> Map.get(:station_pressure_sources_by_candidate_id, %{})
    |> Map.get(ActivityIdentity.activity_id(candidate), [])
  end

  defp station_calendar_pressure_penalty([], _context), do: 0.0

  defp station_calendar_pressure_penalty(_sources, context),
    do: numeric_policy_value(context.scoring_policy, "risk_weight", 1.0)

  defp contact_intent_pressure_statuses(candidate, context) do
    context
    |> Map.get(:contact_intent_pressure_by_candidate_id, %{})
    |> Map.get(ActivityIdentity.activity_id(candidate), [])
  end

  defp contact_intent_pressure_penalty([], _context), do: 0.0

  defp contact_intent_pressure_penalty(_statuses, context),
    do: numeric_policy_value(context.scoring_policy, "risk_weight", 1.0)

  defp contact_contention_resolution_group_ids(candidate, context) do
    context
    |> Map.get(:contact_contention_resolution_group_ids_by_candidate_id, %{})
    |> Map.get(ActivityIdentity.activity_id(candidate), [])
  end

  defp contact_contention_resolution_pressure_penalty([], _context), do: 0.0

  defp contact_contention_resolution_pressure_penalty(_group_ids, context),
    do: numeric_policy_value(context.scoring_policy, "risk_weight", 1.0)

  defp link_capacity_pressure(source, candidate, acc, context) do
    projected_activities = projected_activities(source, candidate, acc, context)

    report =
      LinkCapacity.report(projected_activities, projected_activities,
        policy: context.link_capacity_policy,
        source: "campaign_repair.replacement_projection"
      )

    if LinkCapacityPressureBranches.selected_shortfall_pressure?(report) do
      %{
        penalty: numeric_policy_value(context.scoring_policy, "risk_weight", 1.0),
        shortfall_mb: report["selected_downlink_shortfall_mb"]
      }
    else
      %{penalty: 0.0, shortfall_mb: nil}
    end
  end

  defp projected_activities(source, candidate, acc, context) do
    future_planned_activities =
      Enum.filter(
        context.planned_activities,
        &(activity_sort_key(&1) > activity_sort_key(source))
      )

    acc.activities ++ [candidate | future_planned_activities]
  end

  defp resource_projection_pressure(
         _source,
         _candidate,
         _acc,
         %{source_resource_summaries: []}
       ),
       do: %{penalty: 0.0, risk_indicators: []}

  defp resource_projection_pressure(source, candidate, acc, context) do
    risk_indicators =
      source
      |> projected_activities(candidate, acc, context)
      |> ResourceProjection.report(context.source_resource_summaries,
        model: "thin_repair_replacement_resource_projection",
        source: "source_resource_summaries"
      )
      |> ResourceProjectionRisk.risk_indicators()
      |> Enum.map(&Map.put(&1, "candidate_id", ActivityIdentity.activity_id(candidate)))

    %{
      penalty:
        length(risk_indicators) *
          numeric_policy_value(context.scoring_policy, "risk_weight", 1.0),
      risk_indicators: risk_indicators
    }
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

  defp negative_penalty(value) when value == 0, do: 0.0
  defp negative_penalty(value), do: -value

  defp maybe_put_nonempty(map, _key, []), do: map
  defp maybe_put_nonempty(map, key, values), do: Map.put(map, key, values)

  defp maybe_put_non_nil(map, _key, nil), do: map
  defp maybe_put_non_nil(map, key, value), do: Map.put(map, key, value)
end
