defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.AggregateMaps.ListMaps.NumericListMaps do
  @moduledoc false

  alias __MODULE__.NumericValues

  def merge(list_maps) do
    list_maps
    |> Enum.reject(&(&1 in [nil, %{}]))
    |> Enum.reduce(%{}, fn list_map, acc ->
      Enum.reduce(list_map, acc, fn {key, values}, acc ->
        values = NumericValues.from(values)

        if values == [] do
          acc
        else
          Map.update(acc, to_string(key), values, fn current ->
            (current ++ values)
            |> Enum.uniq()
            |> Enum.sort()
          end)
        end
      end)
    end)
    |> non_empty_map()
  end

  defp non_empty_map(map) when map_size(map) == 0, do: nil
  defp non_empty_map(map), do: map
end
