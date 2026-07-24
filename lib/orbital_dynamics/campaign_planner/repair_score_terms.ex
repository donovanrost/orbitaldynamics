defmodule OrbitalDynamics.CampaignPlanner.RepairScoreTerms do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    ActivityIdentity,
    ContactIntentPressureBranches,
    DownlinkActivityNormalization,
    LinkCapacityPressureBranches,
    OperationalReadinessPressureEvents,
    QualityGatePressureEvents,
    RepairContactAllocationPressure,
    RepairContactContentionResolutionPressure,
    RepairReadinessPressure,
    RepairRefreshPressure,
    RepairSourceFilterPressure,
    ResourceProjectionRisk,
    ScalarValues,
    StationCalendarPressureBranches,
    ValueEncoding
  }

  def build(
        activities,
        deltas,
        resource_projection_report,
        link_capacity_report,
        station_calendar_report,
        contact_filter_report,
        contact_allocation_report,
        contact_contention_resolution_report,
        contact_intents,
        resource_filter_report,
        candidate_diff_report,
        freshness_report,
        refresh_budget_report,
        candidate_rejection_report,
        operational_readiness_report,
        quality_gate_report,
        scoring_policy
      ) do
    build(
      activities,
      deltas,
      resource_projection_report,
      link_capacity_report,
      station_calendar_report,
      contact_filter_report,
      contact_allocation_report,
      contact_contention_resolution_report,
      contact_intents,
      resource_filter_report,
      candidate_diff_report,
      freshness_report,
      refresh_budget_report,
      candidate_rejection_report,
      operational_readiness_report,
      quality_gate_report,
      scoring_policy,
      callbacks()
    )
  end

  def build(
        activities,
        deltas,
        resource_projection_report,
        link_capacity_report,
        station_calendar_report,
        contact_filter_report,
        contact_allocation_report,
        contact_contention_resolution_report,
        contact_intents,
        resource_filter_report,
        candidate_diff_report,
        freshness_report,
        refresh_budget_report,
        candidate_rejection_report,
        operational_readiness_report,
        quality_gate_report,
        scoring_policy,
        callbacks
      ) do
    candidate_score = Keyword.fetch!(callbacks, :candidate_score)
    numeric_policy_value = Keyword.fetch!(callbacks, :numeric_policy_value)

    activity_score = activities |> Enum.map(candidate_score) |> Enum.sum()

    churn_count =
      Enum.count(deltas, &(&1.repair_action in ["moved", "replaced", "canceled", "suppressed"]))

    moved_seconds =
      activities
      |> Enum.map(&(get_in(&1, ["repair", "schedule_churn_s"]) || 0.0))
      |> Enum.sum()

    churn_penalty =
      churn_count * numeric_policy_value.(scoring_policy, "schedule_churn_cost_weight", 100.0)

    move_penalty =
      moved_seconds * numeric_policy_value.(scoring_policy, "schedule_move_cost_weight", 0.01)

    resource_projection_pressure_count =
      repair_resource_projection_pressure_count(resource_projection_report)

    link_capacity_pressure_count = repair_link_capacity_pressure_count(link_capacity_report)

    station_calendar_pressure_count =
      repair_station_calendar_pressure_count(
        station_calendar_report,
        contact_allocation_report,
        activities
      )

    contact_filter_pressure_count =
      RepairSourceFilterPressure.suppressed_count(contact_filter_report)

    contact_allocation_pressure_count =
      RepairContactAllocationPressure.unusable_count(
        contact_allocation_report,
        contact_allocation_callbacks(callbacks)
      )

    contact_contention_resolution_pressure_count =
      RepairContactContentionResolutionPressure.selected_count(
        contact_contention_resolution_report,
        activities
      )

    contact_intent_pressure_count =
      repair_contact_intent_pressure_count(contact_intents, activities)

    resource_filter_pressure_count =
      RepairSourceFilterPressure.suppressed_count(resource_filter_report)

    candidate_diff_pressure_count =
      RepairRefreshPressure.candidate_diff_count(candidate_diff_report)

    refresh_freshness_pressure_count =
      RepairRefreshPressure.freshness_count(freshness_report)

    refresh_budget_pressure_count = RepairRefreshPressure.budget_count(refresh_budget_report)

    candidate_rejection_pressure_count =
      RepairSourceFilterPressure.candidate_rejection_count(
        candidate_rejection_report,
        Keyword.fetch!(callbacks, :stringify_keys)
      )

    operational_readiness_pressure_count =
      RepairReadinessPressure.operational_count(
        operational_readiness_report,
        Keyword.fetch!(callbacks, :operational_readiness_reviewable?)
      )

    quality_gate_pressure_count =
      RepairReadinessPressure.quality_gate_count(
        quality_gate_report,
        Keyword.fetch!(callbacks, :quality_gate_reviewable?)
      )

    resource_projection_pressure_penalty =
      -resource_projection_pressure_count *
        numeric_policy_value.(scoring_policy, "risk_weight", 1.0)

    link_capacity_pressure_penalty =
      -link_capacity_pressure_count *
        numeric_policy_value.(scoring_policy, "risk_weight", 1.0)

    station_calendar_pressure_penalty =
      -station_calendar_pressure_count *
        numeric_policy_value.(scoring_policy, "risk_weight", 1.0)

    contact_filter_pressure_penalty =
      -contact_filter_pressure_count *
        numeric_policy_value.(scoring_policy, "risk_weight", 1.0)

    contact_allocation_pressure_penalty =
      -contact_allocation_pressure_count *
        numeric_policy_value.(scoring_policy, "risk_weight", 1.0)

    contact_contention_resolution_pressure_penalty =
      -contact_contention_resolution_pressure_count *
        numeric_policy_value.(scoring_policy, "risk_weight", 1.0)

    contact_intent_pressure_penalty =
      -contact_intent_pressure_count *
        numeric_policy_value.(scoring_policy, "risk_weight", 1.0)

    resource_filter_pressure_penalty =
      -resource_filter_pressure_count *
        numeric_policy_value.(scoring_policy, "risk_weight", 1.0)

    candidate_diff_pressure_penalty =
      -candidate_diff_pressure_count *
        numeric_policy_value.(scoring_policy, "risk_weight", 1.0)

    refresh_freshness_pressure_penalty =
      -refresh_freshness_pressure_count *
        numeric_policy_value.(scoring_policy, "risk_weight", 1.0)

    refresh_budget_pressure_penalty =
      -refresh_budget_pressure_count *
        numeric_policy_value.(scoring_policy, "risk_weight", 1.0)

    candidate_rejection_pressure_penalty =
      -candidate_rejection_pressure_count *
        numeric_policy_value.(scoring_policy, "risk_weight", 1.0)

    operational_readiness_pressure_penalty =
      -operational_readiness_pressure_count *
        numeric_policy_value.(scoring_policy, "risk_weight", 1.0)

    quality_gate_pressure_penalty =
      -quality_gate_pressure_count *
        numeric_policy_value.(scoring_policy, "risk_weight", 1.0)

    score_terms = %{
      "activity_score" => activity_score,
      "schedule_churn_penalty" => -churn_penalty,
      "schedule_move_penalty" => -move_penalty
    }

    score_terms
    |> maybe_put_positive_pressure_term(
      resource_projection_pressure_count,
      "resource_projection_pressure_penalty",
      resource_projection_pressure_penalty
    )
    |> maybe_put_positive_pressure_term(
      link_capacity_pressure_count,
      "link_capacity_pressure_penalty",
      link_capacity_pressure_penalty
    )
    |> maybe_put_positive_pressure_term(
      station_calendar_pressure_count,
      "station_calendar_pressure_penalty",
      station_calendar_pressure_penalty
    )
    |> maybe_put_positive_pressure_term(
      contact_filter_pressure_count,
      "contact_filter_pressure_penalty",
      contact_filter_pressure_penalty
    )
    |> maybe_put_positive_pressure_term(
      contact_allocation_pressure_count,
      "contact_allocation_pressure_penalty",
      contact_allocation_pressure_penalty
    )
    |> maybe_put_positive_pressure_term(
      contact_contention_resolution_pressure_count,
      "contact_contention_resolution_pressure_penalty",
      contact_contention_resolution_pressure_penalty
    )
    |> maybe_put_positive_pressure_term(
      contact_intent_pressure_count,
      "contact_intent_pressure_penalty",
      contact_intent_pressure_penalty
    )
    |> maybe_put_positive_pressure_term(
      resource_filter_pressure_count,
      "resource_filter_pressure_penalty",
      resource_filter_pressure_penalty
    )
    |> maybe_put_positive_pressure_term(
      candidate_diff_pressure_count,
      "candidate_diff_pressure_penalty",
      candidate_diff_pressure_penalty
    )
    |> maybe_put_positive_pressure_term(
      refresh_freshness_pressure_count,
      "refresh_freshness_pressure_penalty",
      refresh_freshness_pressure_penalty
    )
    |> maybe_put_positive_pressure_term(
      refresh_budget_pressure_count,
      "refresh_budget_pressure_penalty",
      refresh_budget_pressure_penalty
    )
    |> maybe_put_positive_pressure_term(
      candidate_rejection_pressure_count,
      "candidate_rejection_pressure_penalty",
      candidate_rejection_pressure_penalty
    )
    |> maybe_put_positive_pressure_term(
      operational_readiness_pressure_count,
      "operational_readiness_pressure_penalty",
      operational_readiness_pressure_penalty
    )
    |> maybe_put_positive_pressure_term(
      quality_gate_pressure_count,
      "quality_gate_pressure_penalty",
      quality_gate_pressure_penalty
    )
  end

  defp maybe_put_positive_pressure_term(score_terms, count, term_key, penalty) when count > 0 do
    Map.put(score_terms, term_key, penalty)
  end

  defp maybe_put_positive_pressure_term(score_terms, _count, _term_key, _penalty),
    do: score_terms

  defp repair_contact_intent_pressure_count(contact_intents, activities)
       when is_list(contact_intents) and is_list(activities) do
    selected_activity_ids =
      activities
      |> Enum.filter(&DownlinkActivityNormalization.downlink?/1)
      |> Enum.map(&ActivityIdentity.activity_id/1)
      |> Enum.reject(&(&1 in [nil, ""]))
      |> MapSet.new()

    contact_intents
    |> Enum.filter(&is_map/1)
    |> Enum.map(&{&1, "campaign_repair.source_contact_intents"})
    |> ContactIntentPressureBranches.identity_set()
    |> Enum.map(&elem(&1, 1))
    |> MapSet.new()
    |> MapSet.intersection(selected_activity_ids)
    |> MapSet.size()
  end

  defp repair_contact_intent_pressure_count(_contact_intents, _activities), do: 0

  defp repair_link_capacity_pressure_count(%{} = report),
    do: if(LinkCapacityPressureBranches.selected_shortfall_pressure?(report), do: 1, else: 0)

  defp repair_link_capacity_pressure_count(_report), do: 0

  defp repair_station_calendar_pressure_count(
         station_calendar_report,
         contact_allocation_report,
         activities
       )
       when is_list(activities) do
    selected_activity_ids =
      activities
      |> Enum.map(&Map.get(&1, "id"))
      |> Enum.reject(&(&1 in [nil, ""]))
      |> MapSet.new()

    calendar_pressure_rows =
      case station_calendar_report do
        %{"affected_contacts" => rows} when is_list(rows) ->
          Enum.filter(rows, fn row ->
            MapSet.member?(selected_activity_ids, Map.get(row, "contact_id")) and
              StationCalendarPressureBranches.pressure?(row)
          end)

        _report ->
          []
      end

    calendar_pressure_candidate_ids =
      calendar_pressure_rows
      |> Enum.map(&Map.get(&1, "contact_id"))
      |> Enum.reject(&(&1 in [nil, ""]))
      |> MapSet.new()

    allocation_pressure_count =
      contact_allocation_report
      |> RepairContactAllocationPressure.candidate_ids()
      |> MapSet.intersection(selected_activity_ids)
      |> MapSet.difference(calendar_pressure_candidate_ids)
      |> MapSet.size()

    length(calendar_pressure_rows) + allocation_pressure_count
  end

  defp repair_station_calendar_pressure_count(_report, _allocation_report, _activities), do: 0

  defp repair_resource_projection_pressure_count(resource_projection_report) do
    resource_projection_report
    |> ResourceProjectionRisk.risk_indicators()
    |> length()
  end

  defp callbacks,
    do: [
      candidate_score: &candidate_score/1,
      numeric_policy_value: &numeric_policy_value/3,
      stringify_keys: &ValueEncoding.stringify_keys/1,
      normalize_contact_allocation_row: &RepairContactAllocationPressure.normalize_row/1,
      contact_allocation_unusable_candidate?:
        &RepairContactAllocationPressure.unusable_candidate?/1,
      operational_readiness_reviewable?: &OperationalReadinessPressureEvents.reviewable?/1,
      quality_gate_reviewable?: &QualityGatePressureEvents.reviewable?/1
    ]

  defp candidate_score(candidate),
    do: ScalarValues.numeric_or_nil(Map.get(candidate, "score")) || 0.0

  defp numeric_policy_value(policy, key, default) do
    case ScalarValues.numeric_or_nil(Map.get(policy, key, default)) do
      value when is_number(value) -> value
      _value -> default
    end
  end

  defp contact_allocation_callbacks(callbacks) do
    [
      stringify_keys: Keyword.fetch!(callbacks, :stringify_keys),
      normalize_row: Keyword.fetch!(callbacks, :normalize_contact_allocation_row),
      unusable_candidate?: Keyword.fetch!(callbacks, :contact_allocation_unusable_candidate?)
    ]
  end
end
