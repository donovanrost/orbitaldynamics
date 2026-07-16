defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.CommandWindow.SourceReportFields.Flattened do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.CommandWindow.SourceReportFields.Values

  def source_report_fields(source_reports) do
    %{
      "source_report_command_window_contract" =>
        source_report_family_field(source_reports, "contract"),
      "source_report_command_window_count" =>
        source_report_family_identity_count(source_reports, "count"),
      "source_report_command_window_row_count" =>
        source_report_family_identity_count(source_reports, "row_count"),
      "source_report_command_window_paths" =>
        source_report_family_identity_field(source_reports, "paths"),
      "source_report_command_window_command_feedback_count" =>
        source_report_family_count(source_reports, "command_feedback_count"),
      "source_report_command_window_input_keys" =>
        source_report_family_merge_string_lists(source_reports, "input_keys"),
      "source_report_command_window_direction_counts" =>
        source_report_family_merge_count_maps(source_reports, "direction_counts"),
      "source_report_command_window_activity_ids_by_direction" =>
        source_report_family_merge_string_list_maps(source_reports, "activity_ids_by_direction"),
      "source_report_command_window_window_ids_by_direction" =>
        source_report_family_merge_string_list_maps(source_reports, "window_ids_by_direction"),
      "source_report_command_window_direction_routing" =>
        source_report_family_field(source_reports, "direction_routing"),
      "source_report_command_window_required_operator_action_counts" =>
        source_report_family_merge_count_maps(source_reports, "required_operator_action_counts")
    }
  end

  defp source_report_family_reports(source_reports) do
    source_reports
    |> Map.take(["command_window_report"])
    |> Map.values()
  end

  defp source_report_family_count(source_reports, field) do
    if Map.has_key?(source_reports, "command_window_report") do
      source_reports
      |> source_report_family_reports()
      |> Enum.map(&Values.numeric_report_count(&1, field))
      |> Enum.sum()
      |> Values.report_count()
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
    case Map.get(source_reports, "command_window_report") do
      %{} = summary ->
        not is_nil(Map.get(summary, "count")) and not is_nil(Map.get(summary, "row_count"))

      _summary ->
        false
    end
  end

  defp source_report_family_field(source_reports, field) do
    source_reports
    |> Map.get("command_window_report", %{})
    |> Map.get(field)
  end

  defp source_report_family_merge_count_maps(source_reports, field) do
    source_reports
    |> source_report_family_reports()
    |> Enum.map(&Map.get(&1, field))
    |> Values.merge_count_maps()
  end

  defp source_report_family_merge_string_list_maps(source_reports, field) do
    source_reports
    |> source_report_family_reports()
    |> Enum.map(&Map.get(&1, field))
    |> Values.merge_string_list_maps()
  end

  defp source_report_family_merge_string_lists(source_reports, field) do
    source_reports
    |> source_report_family_reports()
    |> Enum.flat_map(&(Map.get(&1, field) |> List.wrap()))
    |> Values.sorted_string_values()
    |> case do
      [] -> nil
      values -> values
    end
  end
end
