defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.QualityGate.SourceReportFields.Aggregation do
  @moduledoc false

  alias __MODULE__.Values

  def source_report_family_reports(source_reports) do
    source_reports
    |> Map.take(["quality_gate_report"])
    |> Map.values()
  end

  def source_report_family_count(source_reports, field) do
    if Map.has_key?(source_reports, "quality_gate_report") do
      source_reports
      |> source_report_family_reports()
      |> Enum.map(&Values.numeric_report_count(&1, field))
      |> Enum.sum()
      |> Values.report_count()
    end
  end

  def source_report_quality_gate_status_row_ids(source_reports, status, fallback_field) do
    if Map.has_key?(source_reports, "quality_gate_report") do
      source_reports
      |> source_report_family_reports()
      |> Enum.flat_map(&quality_gate_status_row_ids(&1, status, fallback_field))
      |> Values.sorted_string_values()
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

  def source_report_family_has_identity_counts?(source_reports) do
    case Map.get(source_reports, "quality_gate_report") do
      %{} = summary ->
        not is_nil(Map.get(summary, "count")) and not is_nil(Map.get(summary, "row_count"))

      _summary ->
        false
    end
  end

  def source_report_family_field(source_reports, field) do
    source_reports
    |> Map.get("quality_gate_report", %{})
    |> Map.get(field)
  end

  def source_report_family_merge_count_maps(source_reports, field) do
    source_reports
    |> source_report_family_reports()
    |> Enum.map(&Map.get(&1, field))
    |> Values.merge_count_maps()
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
    |> Enum.map(&Map.get(&1, field))
    |> Values.merge_string_lists()
  end

  def compact_map(map) when is_map(map) do
    Values.compact_map(map)
  end

  defp quality_gate_status_row_ids(report, status, fallback_field) do
    case Map.get(report, "quality_gate_row_ids_by_status") do
      %{} = row_ids_by_status ->
        quality_gate_summary_list_map_values(row_ids_by_status, status)

      _row_ids_by_status ->
        report
        |> Map.get(fallback_field)
        |> Values.list_value()
    end
  end

  defp quality_gate_summary_list_map_values(%{} = values_by_key, key) do
    values_by_key
    |> Map.get(key)
    |> Values.list_value()
  end
end
