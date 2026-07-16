defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelineIntegrity.SourceReportFields.Aggregation do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ValueEncoding

  def source_report_family_count(source_reports, field) do
    if Map.has_key?(source_reports, "timeline_integrity_report") do
      source_reports
      |> source_report_family_reports()
      |> Enum.map(&numeric_report_count(&1, field))
      |> Enum.sum()
      |> report_count()
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
    |> Map.get("timeline_integrity_report", %{})
    |> Map.get(field)
  end

  def source_report_family_merge_count_maps(source_reports, field) do
    source_reports
    |> source_report_family_reports()
    |> Enum.map(&Map.get(&1, field))
    |> merge_count_maps()
  end

  defp source_report_family_reports(source_reports) do
    source_reports
    |> Map.take(["timeline_integrity_report"])
    |> Map.values()
  end

  defp source_report_family_has_identity_counts?(source_reports) do
    case Map.get(source_reports, "timeline_integrity_report") do
      %{} = summary ->
        not is_nil(Map.get(summary, "count")) and not is_nil(Map.get(summary, "row_count"))

      _summary ->
        false
    end
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

  defp numeric_value(value), do: ValueEncoding.numeric_value(value)

  defp non_empty_map(map) when map_size(map) == 0, do: nil
  defp non_empty_map(map), do: map
end
