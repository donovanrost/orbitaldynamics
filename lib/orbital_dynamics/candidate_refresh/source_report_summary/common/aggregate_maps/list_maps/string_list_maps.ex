defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.AggregateMaps.ListMaps.StringListMaps do
  @moduledoc false

  alias __MODULE__.NestedMaps
  alias __MODULE__.StringValues

  def merge(list_maps) do
    list_maps
    |> Enum.reject(&(&1 in [nil, %{}]))
    |> Enum.reduce(%{}, fn list_map, acc ->
      Enum.reduce(list_map, acc, fn {key, values}, acc ->
        values = StringValues.from(values)

        Map.update(acc, to_string(key), values, fn current ->
          (current ++ values)
          |> Enum.uniq()
        end)
      end)
    end)
    |> non_empty_map()
  end

  def merge_nested(list_maps), do: NestedMaps.merge(list_maps, &merge/1)

  defp non_empty_map(map) when map_size(map) == 0, do: nil
  defp non_empty_map(map), do: map
end
