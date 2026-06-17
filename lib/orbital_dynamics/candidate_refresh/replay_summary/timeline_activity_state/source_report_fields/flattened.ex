defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelineActivityState.SourceReportFields.Flattened do
  @moduledoc false

  def source_report_fields(source_reports) do
    %{
      "source_report_timeline_activity_state_contract" =>
        source_report_family_field(source_reports, "contract"),
      "source_report_timeline_activity_state_count" =>
        source_report_family_identity_count(source_reports, "count"),
      "source_report_timeline_activity_state_row_count" =>
        source_report_family_identity_count(source_reports, "row_count"),
      "source_report_timeline_activity_state_paths" =>
        source_report_family_identity_field(source_reports, "paths"),
      "source_report_timeline_activity_state_source_summary_model_counts" =>
        source_report_family_merge_count_maps(source_reports, "source_summary_model_counts"),
      "source_report_timeline_activity_state_source_summary_schema_contract_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          "source_summary_schema_contract_counts"
        ),
      "source_report_timeline_activity_state_review_required_count" =>
        source_report_family_count(source_reports, "review_required_count"),
      "source_report_timeline_activity_state_invalid_activity_input_count" =>
        source_report_family_count(source_reports, "invalid_activity_input_count"),
      "source_report_timeline_activity_state_invalid_activity_input_reason_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          "invalid_activity_input_reason_counts"
        ),
      "source_report_timeline_activity_state_state_status_counts" =>
        source_report_family_merge_count_maps(source_reports, "state_status_counts"),
      "source_report_timeline_activity_state_transition_decision_counts" =>
        source_report_family_merge_count_maps(source_reports, "transition_decision_counts"),
      "source_report_timeline_activity_state_required_operator_action_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          "required_operator_action_counts"
        ),
      "source_report_timeline_activity_state_import_action_counts" =>
        source_report_family_merge_count_maps(source_reports, "import_action_counts"),
      "source_report_timeline_activity_state_activity_id_counts" =>
        source_report_family_merge_count_maps(source_reports, "activity_id_counts"),
      "source_report_timeline_activity_state_timeline_id_counts" =>
        source_report_family_merge_count_maps(source_reports, "timeline_id_counts"),
      "source_report_timeline_activity_state_review_activity_id_counts" =>
        source_report_family_merge_count_maps(source_reports, "review_activity_id_counts"),
      "source_report_timeline_activity_state_action_routing" =>
        source_report_family_field(source_reports, "action_routing")
    }
  end

  defp source_report_family_reports(source_reports) do
    source_reports
    |> Map.take(["timeline_activity_state"])
    |> Map.values()
  end

  defp source_report_family_count(source_reports, field) do
    if Map.has_key?(source_reports, "timeline_activity_state") do
      source_reports
      |> source_report_family_reports()
      |> Enum.map(&numeric_report_count(&1, field))
      |> Enum.sum()
      |> report_count()
    end
  end

  defp source_report_family_identity_count(source_reports, field) do
    if source_report_family_has_identity_counts?(source_reports) do
      source_report_family_count(source_reports, field)
    end
  end

  defp source_report_family_identity_field(source_reports, field) do
    if source_report_family_has_identity_counts?(source_reports) do
      source_report_family_field(source_reports, field)
    end
  end

  defp source_report_family_has_identity_counts?(source_reports) do
    case Map.get(source_reports, "timeline_activity_state") do
      %{} = summary ->
        not is_nil(Map.get(summary, "count")) and not is_nil(Map.get(summary, "row_count"))

      _summary ->
        false
    end
  end

  defp source_report_family_field(source_reports, field) do
    source_reports
    |> Map.get("timeline_activity_state", %{})
    |> Map.get(field)
  end

  defp source_report_family_merge_count_maps(source_reports, field) do
    source_reports
    |> source_report_family_reports()
    |> Enum.map(&Map.get(&1, field))
    |> merge_count_maps()
  end

  defp numeric_report_count(report, field), do: numeric_value(Map.get(report, field)) || 0

  defp report_count(value) do
    case numeric_value(value) do
      value when is_number(value) and value > 0 -> ceil(value)
      _value -> 0
    end
  end

  defp numeric_value(value) when is_number(value), do: value * 1.0

  defp numeric_value(value) when is_binary(value) do
    case Float.parse(String.trim(value)) do
      {number, ""} -> number
      _parse -> nil
    end
  end

  defp numeric_value(_value), do: nil

  defp merge_count_maps(count_maps) do
    count_maps
    |> Enum.reject(&(&1 in [nil, %{}]))
    |> Enum.reduce(%{}, fn count_map, acc ->
      Enum.reduce(count_map, acc, fn {key, value}, acc ->
        Map.update(acc, key, value, fn
          current when is_integer(current) and is_integer(value) -> current + value
          current -> current
        end)
      end)
    end)
    |> non_empty_map()
  end

  defp non_empty_map(map) when map_size(map) == 0, do: nil
  defp non_empty_map(map), do: map
end
