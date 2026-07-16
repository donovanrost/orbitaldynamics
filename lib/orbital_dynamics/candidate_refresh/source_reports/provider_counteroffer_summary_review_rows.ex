defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferSummaryReviewRows do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      count_values: 1,
      sorted_string_values: 1
    ]

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferImportReadinessRowValues

  def rows(%{} = summary) do
    summary
    |> Map.get("review_rows", [])
    |> Enum.filter(&is_map/1)
    |> Enum.map(&ProviderCounterofferImportReadinessRowValues.stringify_keys/1)
  end

  def count_rows(rows, field),
    do: ProviderCounterofferImportReadinessRowValues.count_rows(rows, field)

  def review_status_counts(summary) do
    count_values([Map.get(summary, "counteroffer_review_status")])
  end

  def review_counteroffer_ids(summary) do
    sorted_string_values(Map.get(summary, "review_counteroffer_ids", []))
  end

  def summary_string_list_map(summary, field) do
    summary
    |> Map.get(field)
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
