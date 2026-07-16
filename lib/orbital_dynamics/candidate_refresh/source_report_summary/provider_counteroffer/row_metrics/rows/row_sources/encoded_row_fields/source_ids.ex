defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ProviderCounteroffer.RowMetrics.Rows.RowSources.EncodedRowFields.SourceIds do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.{
    NormalizedToken,
    StableIds
  }

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [sorted_string_values: 1]

  def by_field(rows, row_field) do
    rows
    |> Enum.flat_map(&pair(&1, row_field))
    |> grouped_source_report_ids()
  end

  defp pair(row, row_field) do
    status = NormalizedToken.value(Map.get(row, row_field))
    counteroffer_id = StableIds.stable_id_or_nil(Map.get(row, "provider_counteroffer_id"))

    if status in [nil, ""] or counteroffer_id in [nil, ""] do
      []
    else
      [{status, counteroffer_id}]
    end
  end

  defp grouped_source_report_ids(pairs) do
    pairs
    |> Enum.reject(fn {key, value} -> key in [nil, ""] or value in [nil, ""] end)
    |> Enum.group_by(fn {key, _value} -> to_string(key) end, fn {_key, value} -> value end)
    |> Map.new(fn {key, values} -> {key, sorted_string_values(values)} end)
    |> non_empty_map()
  end

  defp non_empty_map(map) when map_size(map) == 0, do: nil
  defp non_empty_map(map), do: map
end
