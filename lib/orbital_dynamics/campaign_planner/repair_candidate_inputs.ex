defmodule OrbitalDynamics.CampaignPlanner.RepairCandidateInputs do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    ActivityIdentity,
    ActivityTiming,
    DownlinkActivityNormalization,
    PriorActivityContext,
    RepairSourceReports,
    ScalarValues,
    ValueEncoding
  }

  def candidates(prior_plan, candidate_refresh),
    do: candidates(prior_plan, candidate_refresh, callbacks())

  def candidates(prior_plan, nil, callbacks) do
    prior_plan_candidate_activities = Keyword.fetch!(callbacks, :prior_plan_candidate_activities)

    prior_plan
    |> prior_plan_candidate_activities.()
    |> normalize_candidates(callbacks)
  end

  def candidates(_prior_plan, %{} = candidate_refresh, callbacks) do
    suppressed_candidate_ids = suppressed_candidate_ids(candidate_refresh, callbacks)

    candidate_refresh
    |> Map.get("candidate_activities", [])
    |> normalize_candidates(callbacks)
    |> Enum.reject(&MapSet.member?(suppressed_candidate_ids, activity_id(&1, callbacks)))
  end

  def suppressed_candidate_ids(candidate_refresh),
    do: suppressed_candidate_ids(candidate_refresh, callbacks())

  def suppressed_candidate_ids(candidate_refresh, callbacks) do
    candidate_refresh
    |> contact_suppressed_candidate_ids(callbacks)
    |> MapSet.union(contact_allocation_unusable_candidate_ids(candidate_refresh, callbacks))
    |> MapSet.union(refresh_budget_dropped_candidate_ids(candidate_refresh, callbacks))
    |> MapSet.union(resource_suppressed_candidate_ids(candidate_refresh, callbacks))
  end

  def suppressed_candidate_activities(candidate_refresh),
    do: suppressed_candidate_activities(candidate_refresh, callbacks())

  def suppressed_candidate_activities(nil, _callbacks), do: []

  def suppressed_candidate_activities(%{} = candidate_refresh, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    suppressed_candidate_ids = suppressed_candidate_ids(candidate_refresh, callbacks)

    case Map.get(candidate_refresh, "candidate_activities") do
      rows when is_list(rows) ->
        rows
        |> Enum.filter(&is_map/1)
        |> Enum.map(stringify_keys)
        |> Enum.filter(&MapSet.member?(suppressed_candidate_ids, activity_id(&1, callbacks)))

      _rows ->
        []
    end
  end

  def contact_suppressed_candidate_ids(candidate_refresh),
    do: contact_suppressed_candidate_ids(candidate_refresh, callbacks())

  def contact_suppressed_candidate_ids(candidate_refresh, callbacks) do
    contact_filter_report = Keyword.fetch!(callbacks, :contact_filter_report)
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    contact_filter_contact_id = Keyword.fetch!(callbacks, :contact_filter_contact_id)

    candidate_refresh
    |> contact_filter_report.()
    |> case do
      %{"suppressed_candidates" => rows} when is_list(rows) ->
        rows
        |> Enum.map(stringify_keys)
        |> Enum.map(contact_filter_contact_id)
        |> Enum.reject(&(&1 in [nil, ""]))
        |> MapSet.new()

      _report ->
        MapSet.new()
    end
  end

  def resource_suppressed_candidate_ids(candidate_refresh),
    do: resource_suppressed_candidate_ids(candidate_refresh, callbacks())

  def resource_suppressed_candidate_ids(candidate_refresh, callbacks) do
    resource_filter_report = Keyword.fetch!(callbacks, :resource_filter_report)
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    resource_filter_candidate_id = Keyword.fetch!(callbacks, :resource_filter_candidate_id)

    candidate_refresh
    |> resource_filter_report.()
    |> case do
      %{"suppressed_candidates" => rows} when is_list(rows) ->
        rows
        |> Enum.map(stringify_keys)
        |> Enum.map(resource_filter_candidate_id)
        |> Enum.reject(&(&1 in [nil, ""]))
        |> MapSet.new()

      _report ->
        MapSet.new()
    end
  end

  def contact_allocation_unusable_candidate_ids(candidate_refresh),
    do: contact_allocation_unusable_candidate_ids(candidate_refresh, callbacks())

  def contact_allocation_unusable_candidate_ids(candidate_refresh, callbacks) do
    contact_allocation_report = Keyword.fetch!(callbacks, :contact_allocation_report)
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)

    normalize_contact_allocation_row =
      Keyword.fetch!(callbacks, :normalize_contact_allocation_row)

    contact_allocation_unusable_candidate? =
      Keyword.fetch!(callbacks, :contact_allocation_unusable_candidate?)

    candidate_refresh
    |> contact_allocation_report.()
    |> case do
      %{"rows" => rows} when is_list(rows) ->
        rows
        |> Enum.map(stringify_keys)
        |> Enum.map(normalize_contact_allocation_row)
        |> Enum.filter(contact_allocation_unusable_candidate?)
        |> Enum.map(&Map.get(&1, "contact_id"))
        |> Enum.reject(&(&1 in [nil, ""]))
        |> MapSet.new()

      _report ->
        MapSet.new()
    end
  end

  def refresh_budget_dropped_candidate_ids(candidate_refresh),
    do: refresh_budget_dropped_candidate_ids(candidate_refresh, callbacks())

  def refresh_budget_dropped_candidate_ids(candidate_refresh, callbacks) do
    refresh_budget_report = Keyword.fetch!(callbacks, :refresh_budget_report)

    candidate_refresh
    |> refresh_budget_report.()
    |> case do
      %{} = report ->
        report
        |> Map.get("dropped_candidate_ids", [])
        |> List.wrap()
        |> Enum.reject(&(&1 in [nil, ""]))
        |> MapSet.new()

      _report ->
        MapSet.new()
    end
  end

  def contact_intents(candidate_refresh), do: contact_intents(candidate_refresh, callbacks())

  def contact_intents(nil, _callbacks), do: []

  def contact_intents(%{} = candidate_refresh, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)

    candidate_refresh
    |> Map.get("contact_intents", [])
    |> Enum.map(stringify_keys)
  end

  def resource_summaries(candidate_refresh),
    do: resource_summaries(candidate_refresh, callbacks())

  def resource_summaries(nil, _callbacks), do: []

  def resource_summaries(%{} = candidate_refresh, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)

    candidate_refresh
    |> Map.get("resource_summaries", [])
    |> Enum.map(stringify_keys)
  end

  defp normalize_candidates(activities, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    normalize_downlink_activity = Keyword.fetch!(callbacks, :normalize_downlink_activity)

    activities
    |> Enum.map(stringify_keys)
    |> Enum.map(normalize_downlink_activity)
    |> sort_candidate_activities(callbacks)
  end

  defp sort_candidate_activities(activities, callbacks) do
    activity_start = Keyword.fetch!(callbacks, :activity_start)
    activity_id = Keyword.fetch!(callbacks, :activity_id)

    Enum.sort_by(activities, &{activity_start.(&1), activity_id.(&1)})
  end

  defp activity_id(activity, callbacks) do
    callbacks
    |> Keyword.fetch!(:activity_id)
    |> then(& &1.(activity))
  end

  defp callbacks do
    [
      prior_plan_candidate_activities: &PriorActivityContext.candidate_activities/1,
      stringify_keys: &ValueEncoding.stringify_keys/1,
      normalize_downlink_activity: &DownlinkActivityNormalization.normalize/1,
      activity_id: &ActivityIdentity.activity_id/1,
      activity_start: &ActivityTiming.activity_start/1,
      contact_filter_report: &RepairSourceReports.contact_filter/1,
      contact_allocation_report: &RepairSourceReports.contact_allocation/1,
      resource_filter_report: &RepairSourceReports.resource_filter/1,
      refresh_budget_report: &RepairSourceReports.refresh_budget/1,
      contact_filter_contact_id: &contact_filter_contact_id/1,
      resource_filter_candidate_id: &resource_filter_candidate_id/1,
      normalize_contact_allocation_row: &normalize_contact_allocation_row/1,
      contact_allocation_unusable_candidate?: &contact_allocation_unusable_candidate?/1
    ]
  end

  defp contact_filter_contact_id(row) do
    row["contact_id"] || row["id"] || row["activity_id"]
  end

  defp resource_filter_candidate_id(row) do
    row["activity_id"] || row["contact_id"] || row["id"]
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
