defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferImportReadinessSummaryFallbacks do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      numeric_report_count: 2,
      sorted_string_values: 1
    ]

  def summary_count(summary, field, rows_or_count) do
    case numeric_report_count(summary, field) do
      0 when is_list(rows_or_count) -> length(rows_or_count)
      0 when is_integer(rows_or_count) -> rows_or_count
      count -> count
    end
  end

  def row_counts_or_summary_counts(summary, [], summary_field, _row_field) do
    Map.get(summary, summary_field)
  end

  def row_ids_or_summary_ids(summary, [], summary_field, _row_field) do
    summary
    |> Map.get(summary_field)
    |> map_value_lists()
  end

  defp map_value_lists(%{} = value_map) do
    value_map
    |> Enum.reduce(%{}, fn {key, values}, acc ->
      case sorted_string_values(List.wrap(values)) do
        [] -> acc
        values -> Map.put(acc, to_string(key), values)
      end
    end)
    |> non_empty_map()
  end

  defp map_value_lists(_value), do: nil

  defp non_empty_map(map) when map_size(map) == 0, do: nil
  defp non_empty_map(map), do: map
end
