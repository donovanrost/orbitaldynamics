defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ProviderCounteroffer.RowMetrics.Rows.RowSources.EncodedRowFields do
  @moduledoc false

  alias __MODULE__.SourceIds
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.NormalizedToken

  def count_by_field(rows, row_field) do
    rows
    |> Enum.map(&(Map.get(&1, row_field) |> NormalizedToken.value()))
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.frequencies()
    |> non_empty_map()
  end

  def ids_by_field(rows, row_field) do
    SourceIds.by_field(rows, row_field)
  end

  defp non_empty_map(map) when map_size(map) == 0, do: nil
  defp non_empty_map(map), do: map
end
