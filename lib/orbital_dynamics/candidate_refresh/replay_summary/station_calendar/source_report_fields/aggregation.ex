defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StationCalendar.SourceReportFields.Aggregation do
  @moduledoc false

  alias __MODULE__.Values

  def source_report_family_reports(source_reports) do
    source_reports
    |> Map.take(["station_calendar_report"])
    |> Map.values()
  end

  def source_report_family_count(source_reports, field) do
    if Map.has_key?(source_reports, "station_calendar_report") do
      source_reports
      |> source_report_family_reports()
      |> Enum.map(&Values.numeric_report_count(&1, field))
      |> Enum.sum()
      |> Values.report_count()
    end
  end

  def source_report_family_identity_count(source_reports, field) do
    if source_report_family_has_identity_counts?(source_reports) do
      source_report_family_count(source_reports, field)
    end
  end

  def source_report_family_identity_field(source_reports, field) do
    if source_report_family_has_identity_counts?(source_reports) do
      source_report_family_field(source_reports, field)
    end
  end

  def source_report_family_field(source_reports, field) do
    source_reports
    |> Map.get("station_calendar_report", %{})
    |> Map.get(field)
  end

  def source_report_family_numeric_min(source_reports, field) do
    source_reports
    |> source_report_family_reports()
    |> Enum.map(&(Map.get(&1, field) |> Values.numeric_value()))
    |> Enum.reject(&is_nil/1)
    |> Enum.min(fn -> nil end)
  end

  def source_report_family_merge_count_maps(source_reports, field) do
    source_reports
    |> source_report_family_reports()
    |> Enum.map(&Map.get(&1, field))
    |> Values.merge_count_maps()
  end

  def source_report_family_merge_numeric_lists(source_reports, field) do
    source_reports
    |> source_report_family_reports()
    |> Enum.flat_map(&(Map.get(&1, field) |> List.wrap()))
    |> Values.normalize_number_list()
  end

  def source_report_family_merge_numeric_list_maps(source_reports, field) do
    source_reports
    |> source_report_family_reports()
    |> Enum.map(&Map.get(&1, field))
    |> Values.merge_numeric_list_maps()
  end

  def source_report_family_merge_string_list_maps(source_reports, field) do
    source_reports
    |> source_report_family_reports()
    |> Enum.map(&Map.get(&1, field))
    |> Values.merge_string_list_maps()
  end

  def source_report_family_merge_string_lists(source_reports, field) do
    source_reports
    |> source_report_family_reports()
    |> Enum.flat_map(&(Map.get(&1, field) |> List.wrap()))
    |> Values.sorted_string_values()
    |> case do
      [] -> nil
      values -> values
    end
  end

  defp source_report_family_has_identity_counts?(source_reports) do
    case Map.get(source_reports, "station_calendar_report") do
      %{} = summary ->
        not is_nil(Map.get(summary, "count")) and not is_nil(Map.get(summary, "row_count"))

      _summary ->
        false
    end
  end
end
