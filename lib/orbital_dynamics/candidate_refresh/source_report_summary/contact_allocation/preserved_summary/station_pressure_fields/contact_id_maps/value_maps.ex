defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.PreservedSummary.StationPressureFields.ContactIdMaps.ValueMaps do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      sorted_string_values: 1
    ]

  def flat(%{} = value_map) do
    value_map
    |> Enum.reduce(%{}, fn {key, values}, acc ->
      case sorted_string_values(List.wrap(values)) do
        [] -> acc
        values -> Map.put(acc, to_string(key), values)
      end
    end)
    |> non_empty_map()
  end

  def flat(_value), do: nil

  def nested(%{} = value_map) do
    value_map
    |> Enum.reduce(%{}, fn {outer_key, inner_map}, acc ->
      case flat(inner_map) do
        nil -> acc
        values -> Map.put(acc, to_string(outer_key), values)
      end
    end)
    |> non_empty_map()
  end

  def nested(_value_map), do: nil

  defp non_empty_map(map) when map_size(map) == 0, do: nil
  defp non_empty_map(map), do: map
end
