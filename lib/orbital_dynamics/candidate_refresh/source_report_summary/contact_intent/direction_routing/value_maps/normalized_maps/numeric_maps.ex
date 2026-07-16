defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.DirectionRouting.ValueMaps.NormalizedMaps.NumericMaps do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.NumericValue

  def normalize(value_map) do
    value_map
    |> Enum.reduce(%{}, fn {key, value}, acc ->
      case NumericValue.value(value) do
        value when is_number(value) -> Map.put(acc, to_string(key), value)
        _value -> acc
      end
    end)
    |> non_empty_map()
  end

  def nested_normalize(value_map) do
    value_map
    |> Enum.reduce(%{}, fn {outer_key, inner_map}, acc ->
      case normalize(inner_map) do
        nil -> acc
        values -> Map.put(acc, to_string(outer_key), values)
      end
    end)
    |> non_empty_map()
  end

  defp non_empty_map(map) when map_size(map) == 0, do: nil
  defp non_empty_map(map), do: map
end
