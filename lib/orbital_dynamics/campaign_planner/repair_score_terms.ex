defmodule OrbitalDynamics.CampaignPlanner.RepairScoreTerms do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh

  alias OrbitalDynamics.CampaignPlanner.{
    OperationalReadinessSourceReports,
    OperationalReadinessPressureEvents,
    QualityGatePressureEvents,
    QualityGateSourceReports,
    RefreshFreshnessPressureEvents,
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
      repair_station_calendar_pressure_count(station_calendar_report, activities)

    contact_filter_pressure_count = repair_contact_filter_pressure_count(contact_filter_report)

    contact_allocation_pressure_count =
      repair_contact_allocation_pressure_count(contact_allocation_report, callbacks)

    resource_filter_pressure_count = repair_resource_filter_pressure_count(resource_filter_report)

    candidate_diff_pressure_count =
      repair_candidate_diff_pressure_count(candidate_diff_report)

    refresh_freshness_pressure_count =
      repair_refresh_freshness_pressure_count(freshness_report)

    refresh_budget_pressure_count = repair_refresh_budget_pressure_count(refresh_budget_report)

    candidate_rejection_pressure_count =
      repair_candidate_rejection_pressure_count(candidate_rejection_report, callbacks)

    operational_readiness_pressure_count =
      repair_operational_readiness_pressure_count(operational_readiness_report, callbacks)

    quality_gate_pressure_count =
      repair_quality_gate_pressure_count(quality_gate_report, callbacks)

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

  defp repair_link_capacity_pressure_count(%{"selected_downlink_shortfall_mb" => shortfall}) do
    if positive_number?(ScalarValues.numeric_or_nil(shortfall)), do: 1, else: 0
  end

  defp repair_link_capacity_pressure_count(_report), do: 0

  defp repair_station_calendar_pressure_count(
         %{"affected_contacts" => affected_contacts},
         activities
       )
       when is_list(affected_contacts) and is_list(activities) do
    selected_activity_ids =
      activities
      |> Enum.map(&Map.get(&1, "id"))
      |> Enum.reject(&(&1 in [nil, ""]))
      |> MapSet.new()

    Enum.count(affected_contacts, fn row ->
      MapSet.member?(selected_activity_ids, Map.get(row, "contact_id")) and
        StationCalendarPressureBranches.pressure?(row)
    end)
  end

  defp repair_station_calendar_pressure_count(_report, _activities), do: 0

  defp repair_contact_filter_pressure_count(%{"suppressed_candidates" => rows})
       when is_list(rows),
       do: length(rows)

  defp repair_contact_filter_pressure_count(%{"suppressed_candidate_count" => count})
       when is_number(count),
       do: trunc(count)

  defp repair_contact_filter_pressure_count(_report), do: 0

  defp repair_contact_allocation_pressure_count(%{"rows" => rows}, callbacks)
       when is_list(rows) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)

    normalize_contact_allocation_row =
      Keyword.fetch!(callbacks, :normalize_contact_allocation_row)

    contact_allocation_unusable_candidate? =
      Keyword.fetch!(callbacks, :contact_allocation_unusable_candidate?)

    rows
    |> Enum.map(stringify_keys)
    |> Enum.map(normalize_contact_allocation_row)
    |> Enum.count(contact_allocation_unusable_candidate?)
  end

  defp repair_contact_allocation_pressure_count(
         %{"effective_allocation_status_counts" => %{} = counts},
         _callbacks
       ) do
    Enum.sum([
      numeric_count(Map.get(counts, "blocked")),
      numeric_count(Map.get(counts, "deferred")),
      numeric_count(Map.get(counts, "policy_blocked"))
    ])
  end

  defp repair_contact_allocation_pressure_count(_report, _callbacks), do: 0

  defp repair_resource_filter_pressure_count(%{"suppressed_candidates" => rows})
       when is_list(rows),
       do: length(rows)

  defp repair_resource_filter_pressure_count(%{"suppressed_candidate_count" => count})
       when is_number(count),
       do: trunc(count)

  defp repair_resource_filter_pressure_count(_report), do: 0

  defp repair_candidate_diff_pressure_count(%{} = report) do
    case CandidateRefresh.candidate_diff_replay_summary(%{"candidate_diff_report" => report}) do
      %{"branch_local_diff_pressure" => true} -> 1
      _summary -> 0
    end
  end

  defp repair_candidate_diff_pressure_count(_report), do: 0

  defp repair_refresh_freshness_pressure_count(%{} = report) do
    report
    |> RefreshFreshnessPressureEvents.status()
    |> ScalarValues.normalized_status_token()
    |> then(&if &1 in ["stale", "unknown"], do: 1, else: 0)
  end

  defp repair_refresh_freshness_pressure_count(_report), do: 0

  defp repair_refresh_budget_pressure_count(%{"dropped_candidate_ids" => dropped_ids})
       when is_list(dropped_ids) do
    dropped_ids
    |> Enum.reject(&(&1 in [nil, ""]))
    |> length()
  end

  defp repair_refresh_budget_pressure_count(%{"dropped_candidate_count" => count})
       when is_number(count) and count > 0,
       do: trunc(count)

  defp repair_refresh_budget_pressure_count(%{"invalid_candidate_limit_policy" => true}), do: 1

  defp repair_refresh_budget_pressure_count(_report), do: 0

  defp repair_candidate_rejection_pressure_count(%{"rows" => rows}, callbacks)
       when is_list(rows) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)

    rows
    |> Enum.map(stringify_keys)
    |> Enum.count(&(Map.get(&1, "rejection_status", "rejected") == "rejected"))
  end

  defp repair_candidate_rejection_pressure_count(
         %{"rejected_candidate_ids" => rejected_ids},
         _callbacks
       )
       when is_list(rejected_ids) do
    rejected_ids
    |> Enum.reject(&(&1 in [nil, ""]))
    |> length()
  end

  defp repair_candidate_rejection_pressure_count(
         %{"rejected_candidate_count" => count},
         _callbacks
       )
       when is_number(count) and count > 0,
       do: trunc(count)

  defp repair_candidate_rejection_pressure_count(_report, _callbacks), do: 0

  defp repair_operational_readiness_pressure_count(%{} = report, callbacks) do
    operational_readiness_reviewable? =
      Keyword.fetch!(callbacks, :operational_readiness_reviewable?)

    report
    |> OperationalReadinessSourceReports.pressure_rows_for_report()
    |> Enum.count(operational_readiness_reviewable?)
  end

  defp repair_operational_readiness_pressure_count(_report, _callbacks), do: 0

  defp repair_quality_gate_pressure_count(%{} = report, callbacks) do
    quality_gate_reviewable? = Keyword.fetch!(callbacks, :quality_gate_reviewable?)

    report
    |> QualityGateSourceReports.pressure_rows_for_report()
    |> Enum.count(quality_gate_reviewable?)
  end

  defp repair_quality_gate_pressure_count(_report, _callbacks), do: 0

  defp numeric_count(count) when is_number(count), do: trunc(count)
  defp numeric_count(_count), do: 0

  defp positive_number?(value) when is_number(value), do: value > 0.0
  defp positive_number?(_value), do: false

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
      normalize_contact_allocation_row: &normalize_contact_allocation_row/1,
      contact_allocation_unusable_candidate?: &contact_allocation_unusable_candidate?/1,
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

  defp normalize_contact_allocation_row(row) do
    row
    |> normalize_contact_allocation_status_field("allocation_status")
    |> normalize_contact_allocation_status_field("effective_allocation_status")
    |> normalize_contact_allocation_status_field("review_status")
    |> normalize_contact_allocation_status_field("approval_status")
    |> normalize_contact_allocation_policy_decision()
  end

  defp normalize_contact_allocation_status_field(row, field) do
    case Map.get(row, field) do
      value when value in [nil, ""] -> row
      value -> Map.put(row, field, ScalarValues.normalized_status_token(value))
    end
  end

  defp normalize_contact_allocation_policy_decision(%{"policy_decision" => %{} = decision} = row) do
    decision =
      decision
      |> ValueEncoding.stringify_keys()
      |> normalize_contact_allocation_status_field("classification")

    Map.put(row, "policy_decision", decision)
  end

  defp normalize_contact_allocation_policy_decision(row), do: row

  defp contact_allocation_unusable_candidate?(row) do
    contact_allocation_effective_status(row) in ["deferred", "blocked", "policy_blocked"]
  end

  defp contact_allocation_effective_status(row) do
    Map.get(row, "effective_allocation_status") || Map.get(row, "allocation_status")
  end
end
