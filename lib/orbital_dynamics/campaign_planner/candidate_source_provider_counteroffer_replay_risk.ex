defmodule OrbitalDynamics.CampaignPlanner.CandidateSourceProviderCounterofferReplayRisk do
  @moduledoc false

  def provider_counteroffer(%{"branch_local_counteroffer_pressure" => true} = replay_summary) do
    if provider_counteroffer_scoring_pressure?(replay_summary) do
      provider_counteroffer_pressure_risk(replay_summary)
    else
      []
    end
  end

  def provider_counteroffer(_replay_summary), do: []

  defp provider_counteroffer_scoring_pressure?(replay_summary) do
    Map.get(replay_summary, "branch_local_counteroffer_review_pressure") == true or
      Map.get(replay_summary, "branch_local_counteroffer_cost_pressure") == true or
      Map.get(replay_summary, "branch_local_counteroffer_timing_pressure") == true or
      Map.get(replay_summary, "branch_local_counteroffer_lock_pressure") == true or
      Map.get(replay_summary, "branch_local_counteroffer_import_readiness_pressure") == true or
      Map.get(replay_summary, "branch_local_plan_impact_pressure") == true
  end

  defp provider_counteroffer_pressure_risk(replay_summary) do
    counteroffer_ids =
      [
        Map.get(replay_summary, "review_counteroffer_ids"),
        Map.get(replay_summary, "impact_counteroffer_ids"),
        Map.get(replay_summary, "timing_shift_counteroffer_ids"),
        Map.get(replay_summary, "cost_delta_counteroffer_ids"),
        replay_summary
        |> Map.get("counteroffer_ids_by_import_status", %{})
        |> Map.values(),
        replay_summary
        |> Map.get("counteroffer_ids_by_required_import_action", %{})
        |> Map.values(),
        replay_summary
        |> Map.get("counteroffer_ids_by_lock_deadline_status", %{})
        |> Map.values()
      ]
      |> List.flatten()
      |> sorted_encoded_values()

    [
      %{
        "type" => "provider_counteroffer_review",
        "severity" => "medium",
        "reason" =>
          "candidate source provider-counteroffer replay reports review, cost, timing, lock, import-readiness, or plan-impact pressure",
        "source_report_count" => Map.get(replay_summary, "source_report_count"),
        "source_report_row_count" => Map.get(replay_summary, "source_report_row_count"),
        "source_report_paths" => Map.get(replay_summary, "source_report_paths"),
        "reviewable_count" => Map.get(replay_summary, "reviewable_count"),
        "counteroffer_cost_delta_count" =>
          Map.get(replay_summary, "counteroffer_cost_delta_count"),
        "counteroffer_cost_delta_total" =>
          Map.get(replay_summary, "counteroffer_cost_delta_total"),
        "counteroffer_timing_shift_count" =>
          Map.get(replay_summary, "counteroffer_timing_shift_count"),
        "counteroffer_start_delta_count" =>
          Map.get(replay_summary, "counteroffer_start_delta_count"),
        "counteroffer_end_delta_count" => Map.get(replay_summary, "counteroffer_end_delta_count"),
        "counteroffer_duration_delta_count" =>
          Map.get(replay_summary, "counteroffer_duration_delta_count"),
        "counteroffer_lock_deadline_count" =>
          Map.get(replay_summary, "counteroffer_lock_deadline_count"),
        "earliest_counteroffer_lock_deadline_s" =>
          Map.get(replay_summary, "earliest_counteroffer_lock_deadline_s"),
        "counteroffer_status_counts" => Map.get(replay_summary, "counteroffer_status_counts"),
        "required_operator_action_counts" =>
          Map.get(replay_summary, "required_operator_action_counts"),
        "review_summary_count" => Map.get(replay_summary, "review_summary_count"),
        "counteroffer_review_status_counts" =>
          Map.get(replay_summary, "counteroffer_review_status_counts"),
        "counteroffer_negotiation_state_counts" =>
          Map.get(replay_summary, "counteroffer_negotiation_state_counts"),
        "import_readiness_summary_count" =>
          Map.get(replay_summary, "import_readiness_summary_count"),
        "import_readiness_status_counts" =>
          Map.get(replay_summary, "import_readiness_status_counts"),
        "import_classification_counts" => Map.get(replay_summary, "import_classification_counts"),
        "provider_counteroffer_import_status_counts" =>
          Map.get(replay_summary, "provider_counteroffer_import_status_counts"),
        "counteroffer_lock_deadline_status_counts" =>
          Map.get(replay_summary, "counteroffer_lock_deadline_status_counts"),
        "counteroffer_ids_by_import_status" =>
          Map.get(replay_summary, "counteroffer_ids_by_import_status"),
        "counteroffer_ids_by_required_import_action" =>
          Map.get(replay_summary, "counteroffer_ids_by_required_import_action"),
        "counteroffer_ids_by_lock_deadline_status" =>
          Map.get(replay_summary, "counteroffer_ids_by_lock_deadline_status"),
        "counteroffer_ids" => counteroffer_ids,
        "review_counteroffer_ids" => Map.get(replay_summary, "review_counteroffer_ids"),
        "no_import_required_counteroffer_ids" =>
          Map.get(replay_summary, "no_import_required_counteroffer_ids"),
        "plan_impact_summary_count" => Map.get(replay_summary, "plan_impact_summary_count"),
        "plan_impact_status_counts" => Map.get(replay_summary, "plan_impact_status_counts"),
        "affected_station_calendar_entry_ids" =>
          Map.get(replay_summary, "affected_station_calendar_entry_ids"),
        "affected_provider_entry_ids" => Map.get(replay_summary, "affected_provider_entry_ids"),
        "impact_counteroffer_ids" => Map.get(replay_summary, "impact_counteroffer_ids"),
        "timing_shift_counteroffer_ids" =>
          Map.get(replay_summary, "timing_shift_counteroffer_ids"),
        "cost_delta_counteroffer_ids" => Map.get(replay_summary, "cost_delta_counteroffer_ids"),
        "branch_local_counteroffer_review_pressure" =>
          Map.get(replay_summary, "branch_local_counteroffer_review_pressure"),
        "branch_local_counteroffer_cost_pressure" =>
          Map.get(replay_summary, "branch_local_counteroffer_cost_pressure"),
        "branch_local_counteroffer_timing_pressure" =>
          Map.get(replay_summary, "branch_local_counteroffer_timing_pressure"),
        "branch_local_counteroffer_lock_pressure" =>
          Map.get(replay_summary, "branch_local_counteroffer_lock_pressure"),
        "branch_local_counteroffer_import_readiness_pressure" =>
          Map.get(replay_summary, "branch_local_counteroffer_import_readiness_pressure"),
        "branch_local_plan_impact_pressure" =>
          Map.get(replay_summary, "branch_local_plan_impact_pressure"),
        "feedback_source" => "candidate_source.provider_counteroffer_replay_summary",
        "feedback_scope" => "provider_counteroffer",
        "trust_boundaries" => Map.get(replay_summary, "trust_boundaries")
      }
      |> compact_map()
    ]
  end

  defp sorted_encoded_values(values) do
    values
    |> List.wrap()
    |> List.flatten()
    |> Enum.map(&encode_value/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp encode_value(%_{} = struct), do: struct |> Map.from_struct() |> encode_value()

  defp encode_value(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), encode_value(value)} end)
  end

  defp encode_value(values) when is_list(values) do
    if Keyword.keyword?(values) do
      Map.new(values, fn {key, value} -> {encode_value(key), encode_value(value)} end)
    else
      Enum.map(values, &encode_value/1)
    end
  end

  defp encode_value(value) when is_tuple(value), do: value |> Tuple.to_list() |> encode_value()
  defp encode_value(nil), do: nil
  defp encode_value(value) when is_boolean(value), do: value
  defp encode_value(value) when is_atom(value), do: Atom.to_string(value)
  defp encode_value(value), do: value
end
