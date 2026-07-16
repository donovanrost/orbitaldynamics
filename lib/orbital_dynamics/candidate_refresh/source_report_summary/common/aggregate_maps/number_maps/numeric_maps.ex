defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.AggregateMaps.NumberMaps.NumericMaps do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.NumericValue

  def merge(numeric_maps) do
    numeric_maps
    |> Enum.reject(&(&1 in [nil, %{}]))
    |> Enum.reduce(%{}, fn numeric_map, acc ->
      Enum.reduce(numeric_map, acc, fn {key, value}, acc ->
        case NumericValue.value(value) do
          value when is_number(value) -> Map.update(acc, key, value, &(&1 + value))
          _value -> acc
        end
      end)
    end)
    |> non_empty_map()
  end

  defp non_empty_map(map) when map_size(map) == 0, do: nil
  defp non_empty_map(map), do: map
end
