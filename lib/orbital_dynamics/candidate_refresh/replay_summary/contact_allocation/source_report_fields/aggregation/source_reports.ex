defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.Aggregation.SourceReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.Aggregation.Values

  @family_key "contact_allocation_report"

  def contact_count(source_reports, count_fun) when is_function(count_fun, 1) do
    source_reports
    |> reports()
    |> case do
      [] ->
        nil

      reports ->
        reports
        |> Enum.map(count_fun)
        |> Enum.sum()
        |> Values.report_count()
    end
  end

  def count(source_reports, field) do
    if Map.has_key?(source_reports, @family_key) do
      source_reports
      |> reports()
      |> Enum.map(&Values.numeric_report_count(&1, field))
      |> Enum.sum()
      |> Values.report_count()
    end
  end

  def identity_count(source_reports, field) do
    if has_identity_counts?(source_reports) do
      count(source_reports, field)
    end
  end

  def identity_field(source_reports, field) do
    if has_identity_counts?(source_reports) do
      field(source_reports, field)
    end
  end

  def field(source_reports, field) do
    source_reports
    |> Map.get(@family_key, %{})
    |> Map.get(field)
  end

  def numeric_sum(source_reports, field) do
    source_reports
    |> reports()
    |> Enum.map(&(Map.get(&1, field) |> Values.numeric_value()))
    |> Enum.filter(&is_number/1)
    |> case do
      [] -> nil
      values -> Enum.sum(values)
    end
  end

  def numeric_min(source_reports, field) do
    source_reports
    |> reports()
    |> Enum.map(&(Map.get(&1, field) |> Values.numeric_value()))
    |> Enum.reject(&is_nil/1)
    |> Enum.min(fn -> nil end)
  end

  def merge_count_maps(source_reports, field) do
    source_reports
    |> reports()
    |> Enum.map(&Map.get(&1, field))
    |> Values.merge_count_maps()
  end

  def merge_numeric_maps(source_reports, field) do
    source_reports
    |> reports()
    |> Enum.map(&Map.get(&1, field))
    |> Values.merge_numeric_maps()
  end

  def merge_numeric_lists(source_reports, field) do
    source_reports
    |> reports()
    |> Enum.flat_map(&(Map.get(&1, field) |> List.wrap()))
    |> Values.normalize_number_list()
  end

  def merge_string_list_maps(source_reports, field) do
    source_reports
    |> reports()
    |> Enum.map(&Map.get(&1, field))
    |> Values.merge_string_list_maps()
  end

  def merge_string_list_map_fields(source_reports, fields) do
    source_reports
    |> reports()
    |> Enum.flat_map(fn summary -> Enum.map(fields, &Map.get(summary, &1)) end)
    |> Values.merge_string_list_maps()
  end

  def merge_nested_string_list_maps(source_reports, field) do
    source_reports
    |> reports()
    |> Enum.map(&Map.get(&1, field))
    |> Values.merge_nested_string_list_maps()
  end

  def merge_nested_string_list_map_fields(source_reports, fields) do
    source_reports
    |> reports()
    |> Enum.flat_map(fn summary -> Enum.map(fields, &Map.get(summary, &1)) end)
    |> Values.merge_nested_string_list_maps()
  end

  def merge_string_lists(source_reports, field) do
    source_reports
    |> reports()
    |> Enum.flat_map(&(Map.get(&1, field) |> List.wrap()))
    |> Values.sorted_string_values()
    |> case do
      [] -> nil
      values -> values
    end
  end

  defp reports(source_reports) do
    source_reports
    |> Map.take([@family_key])
    |> Map.values()
  end

  defp has_identity_counts?(source_reports) do
    case Map.get(source_reports, @family_key) do
      %{} = summary ->
        not is_nil(Map.get(summary, "count")) and not is_nil(Map.get(summary, "row_count"))

      _summary ->
        false
    end
  end
end
