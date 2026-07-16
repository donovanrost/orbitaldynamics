defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.DirectionRouting.ValueMaps.NormalizedMaps.ListMaps do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.EncodedValue

  def nested(value_map) do
    value_map
    |> Enum.reduce(%{}, fn {outer_key, inner_map}, acc ->
      case values(inner_map) do
        nil -> acc
        values -> Map.put(acc, to_string(outer_key), values)
      end
    end)
    |> non_empty_map()
  end

  def values(value_map) do
    value_map
    |> Enum.reduce(%{}, fn {key, values}, acc ->
      case sorted_encoded_string_values(List.wrap(values)) do
        [] -> acc
        values -> Map.put(acc, to_string(key), values)
      end
    end)
    |> non_empty_map()
  end

  defp sorted_encoded_string_values(values) when is_list(values) do
    values
    |> Enum.map(&EncodedValue.value/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp non_empty_map(map) when map_size(map) == 0, do: nil
  defp non_empty_map(map), do: map
end
