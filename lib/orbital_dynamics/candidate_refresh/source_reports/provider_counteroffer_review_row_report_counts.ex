defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferReviewRowReportCounts do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferEncoding

  def count_rows(rows, field) do
    rows
    |> Enum.map(&normalized_token(Map.get(&1, field)))
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.frequencies()
    |> non_empty_map()
  end

  defp non_empty_map(map) when map_size(map) == 0, do: nil
  defp non_empty_map(map), do: map

  defp normalized_token(value) do
    value
    |> ProviderCounterofferEncoding.stringify_keys()
    |> case do
      nil ->
        nil

      value ->
        value
        |> String.trim()
        |> String.downcase()
        |> String.replace(~r/[\s-]+/, "_")
        |> String.trim("_")
    end
  end
end
