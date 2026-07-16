defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelinePublication.SourceReportFields.Flattened.Aggregates do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ValueEncoding

  def family_count(source_reports, field) do
    if Map.has_key?(source_reports, "timeline_publication_summary") do
      source_reports
      |> family_reports()
      |> Enum.map(&numeric_report_count(&1, field))
      |> Enum.sum()
      |> report_count()
    end
  end

  def family_identity_count(source_reports, field) do
    if family_has_identity_counts?(source_reports) do
      family_count(source_reports, field)
    end
  end

  def family_identity_field(source_reports, field) do
    if family_has_identity_counts?(source_reports) do
      family_field(source_reports, field)
    end
  end

  def family_field(source_reports, field) do
    source_reports
    |> Map.get("timeline_publication_summary", %{})
    |> Map.get(field)
  end

  def family_merge_count_maps(source_reports, field) do
    source_reports
    |> family_reports()
    |> Enum.map(&Map.get(&1, field))
    |> merge_count_maps()
  end

  def family_merge_string_lists(source_reports, field) do
    source_reports
    |> family_reports()
    |> Enum.flat_map(&(Map.get(&1, field) |> List.wrap()))
    |> sorted_non_empty_values()
  end

  def family_merge_string_list_maps(source_reports, field) do
    source_reports
    |> family_reports()
    |> Enum.map(&Map.get(&1, field))
    |> merge_string_list_maps()
  end

  defp family_reports(source_reports) do
    source_reports
    |> Map.take(["timeline_publication_summary"])
    |> Map.values()
  end

  defp family_has_identity_counts?(source_reports) do
    case Map.get(source_reports, "timeline_publication_summary") do
      %{} = summary ->
        not is_nil(Map.get(summary, "count")) and not is_nil(Map.get(summary, "row_count"))

      _summary ->
        false
    end
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

  defp merge_string_list_maps(list_maps) do
    list_maps
    |> Enum.reject(&(&1 in [nil, %{}]))
    |> Enum.reduce(%{}, fn list_map, acc ->
      Enum.reduce(list_map, acc, fn {key, values}, acc ->
        values =
          values
          |> list_value()
          |> Enum.reject(&(&1 in [nil, ""]))
          |> Enum.map(&to_string/1)

        Map.update(acc, to_string(key), values, fn current ->
          (current ++ values)
          |> Enum.uniq()
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

  defp numeric_value(value), do: ValueEncoding.numeric_value(value)

  defp sorted_non_empty_values(values) do
    values
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.map(&to_string/1)
    |> Enum.uniq()
    |> Enum.sort()
    |> case do
      [] -> nil
      values -> values
    end
  end

  defp list_value(values) when is_list(values), do: values
  defp list_value(_values), do: []

  defp non_empty_map(map) when map_size(map) == 0, do: nil
  defp non_empty_map(map), do: map
end
