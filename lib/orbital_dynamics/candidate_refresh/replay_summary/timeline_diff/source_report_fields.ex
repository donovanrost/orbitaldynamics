defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelineDiff.SourceReportFields do
  @moduledoc false

  def source_report_fields(source_reports, summary) do
    %{
      "source_report_timeline_diff_branch_local_timeline_diff_pressure" =>
        Map.get(summary, "branch_local_timeline_diff_pressure"),
      "source_report_timeline_diff_branch_local_duplicate_identity_pressure" =>
        Map.get(summary, "branch_local_duplicate_identity_pressure"),
      "source_report_timeline_diff_branch_local_removed_activity_pressure" =>
        Map.get(summary, "branch_local_removed_activity_pressure"),
      "source_report_timeline_diff_branch_local_changed_activity_pressure" =>
        Map.get(summary, "branch_local_changed_activity_pressure"),
      "source_report_timeline_diff_branch_local_activity_routing_pressure" =>
        Map.get(summary, "branch_local_activity_routing_pressure"),
      "source_report_timeline_diff_branch_local_operator_review_pressure" =>
        Map.get(summary, "branch_local_operator_review_pressure")
    }
    |> Map.merge(flattened_source_report_fields(source_reports))
  end

  defp flattened_source_report_fields(source_reports) do
    %{
      "source_report_timeline_diff_duplicate_timeline_identity_count" =>
        source_report_family_count(source_reports, "duplicate_timeline_identity_count"),
      "source_report_timeline_diff_duplicate_source_timeline_identity_count" =>
        source_report_family_count(source_reports, "duplicate_source_timeline_identity_count"),
      "source_report_timeline_diff_duplicate_replacement_timeline_identity_count" =>
        source_report_family_count(
          source_reports,
          "duplicate_replacement_timeline_identity_count"
        ),
      "source_report_timeline_diff_removed_downlink_count" =>
        source_report_family_count(source_reports, "removed_downlink_count"),
      "source_report_timeline_diff_removed_observation_count" =>
        source_report_family_count(source_reports, "removed_observation_count"),
      "source_report_timeline_diff_changed_downlink_shortfall_count" =>
        source_report_family_count(source_reports, "changed_downlink_shortfall_count"),
      "source_report_timeline_diff_changed_contact_feedback_count" =>
        source_report_family_count(source_reports, "changed_contact_feedback_count"),
      "source_report_timeline_diff_changed_observation_count" =>
        source_report_family_count(source_reports, "changed_observation_count"),
      "source_report_timeline_diff_changed_observation_quality_feedback_count" =>
        source_report_family_count(
          source_reports,
          "changed_observation_quality_feedback_count"
        ),
      "source_report_timeline_diff_changed_command_feedback_count" =>
        source_report_family_count(source_reports, "changed_command_feedback_count"),
      "source_report_timeline_diff_changed_maneuver_feedback_count" =>
        source_report_family_count(source_reports, "changed_maneuver_feedback_count"),
      "source_report_timeline_diff_status_counts" =>
        source_report_family_merge_count_maps(source_reports, "diff_status_counts"),
      "source_report_timeline_diff_required_operator_action_counts" =>
        source_report_family_merge_count_maps(source_reports, "required_operator_action_counts"),
      "source_report_timeline_diff_duplicate_timeline_identity_scope_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          "duplicate_timeline_identity_scope_counts"
        ),
      "source_report_timeline_diff_source_activity_id_counts" =>
        source_report_family_merge_count_maps(source_reports, "source_activity_id_counts"),
      "source_report_timeline_diff_replacement_activity_id_counts" =>
        source_report_family_merge_count_maps(source_reports, "replacement_activity_id_counts")
    }
  end

  defp source_report_family_reports(source_reports) do
    source_reports
    |> Map.take(["timeline_diff_report"])
    |> Map.values()
  end

  defp source_report_family_count(source_reports, field) do
    if Map.has_key?(source_reports, "timeline_diff_report") do
      source_reports
      |> source_report_family_reports()
      |> Enum.map(&numeric_report_count(&1, field))
      |> Enum.sum()
      |> report_count()
    end
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
