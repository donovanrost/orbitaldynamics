defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelineFeedback.SourceReportFields do
  @moduledoc false

  def source_report_fields(source_reports, summary) do
    %{
      "source_report_timeline_feedback_branch_local_timeline_feedback_pressure" =>
        Map.get(summary, "branch_local_timeline_feedback_pressure"),
      "source_report_timeline_feedback_branch_local_feedback_input_pressure" =>
        Map.get(summary, "branch_local_feedback_input_pressure"),
      "source_report_timeline_feedback_branch_local_activity_routing_pressure" =>
        Map.get(summary, "branch_local_activity_routing_pressure"),
      "source_report_timeline_feedback_branch_local_match_review_pressure" =>
        Map.get(summary, "branch_local_match_review_pressure"),
      "source_report_timeline_feedback_branch_local_import_review_pressure" =>
        Map.get(summary, "branch_local_import_review_pressure"),
      "source_report_timeline_feedback_branch_local_station_reservation_pressure" =>
        Map.get(summary, "branch_local_station_reservation_pressure")
    }
    |> Map.merge(flattened_source_report_fields(source_reports))
  end

  defp flattened_source_report_fields(source_reports) do
    %{
      "source_report_timeline_feedback_contract" =>
        source_report_family_field(source_reports, "contract"),
      "source_report_timeline_feedback_count" =>
        source_report_family_identity_count(source_reports, "count"),
      "source_report_timeline_feedback_row_count" =>
        source_report_family_identity_count(source_reports, "row_count"),
      "source_report_timeline_feedback_paths" =>
        source_report_family_identity_field(source_reports, "paths"),
      "source_report_timeline_feedback_cadence_import_status_counts" =>
        source_report_family_merge_count_maps(source_reports, "cadence_import_status_counts"),
      "source_report_timeline_feedback_activity_id_counts" =>
        source_report_family_merge_count_maps(source_reports, "activity_id_counts")
    }
  end

  defp source_report_family_reports(source_reports) do
    source_reports
    |> Map.take(["timeline_feedback_report"])
    |> Map.values()
  end

  defp source_report_family_count(source_reports, field) do
    if Map.has_key?(source_reports, "timeline_feedback_report") do
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
    case Map.get(source_reports, "timeline_feedback_report") do
      %{} = summary ->
        not is_nil(Map.get(summary, "count")) and not is_nil(Map.get(summary, "row_count"))

      _summary ->
        false
    end
  end

  defp source_report_family_field(source_reports, field) do
    source_reports
    |> Map.get("timeline_feedback_report", %{})
    |> Map.get(field)
  end

  defp source_report_family_merge_count_maps(source_reports, field) do
    source_reports
    |> source_report_family_reports()
    |> Enum.map(&Map.get(&1, field))
    |> merge_count_maps()
  end

  defp numeric_report_count(report, field), do: numeric_value(Map.get(report, field)) || 0

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

  defp non_empty_map(map) when map_size(map) == 0, do: nil
  defp non_empty_map(map), do: map
end
