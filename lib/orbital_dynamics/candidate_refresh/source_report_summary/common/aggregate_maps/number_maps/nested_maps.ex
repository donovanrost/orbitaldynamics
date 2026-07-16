defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.AggregateMaps.NumberMaps.NestedMaps do
  @moduledoc false

  def merge(nested_maps, inner_merge) when is_function(inner_merge, 1) do
    nested_maps
    |> Enum.reject(&(&1 in [nil, %{}]))
    |> Enum.reduce(%{}, fn nested_map, acc ->
      Enum.reduce(nested_map, acc, fn {outer_key, inner_map}, acc ->
        merge_inner_map(acc, outer_key, inner_map, inner_merge)
      end)
    end)
    |> non_empty_map()
  end

  defp merge_inner_map(acc, outer_key, %{} = inner_map, inner_merge) do
    outer_key = to_string(outer_key)
    merged_inner = inner_merge.([Map.get(acc, outer_key, %{}), inner_map])

    if is_nil(merged_inner) do
      acc
    else
      Map.put(acc, outer_key, merged_inner)
    end
  end

  defp merge_inner_map(acc, _outer_key, _inner_map, _inner_merge), do: acc

  defp non_empty_map(map) when map_size(map) == 0, do: nil
  defp non_empty_map(map), do: map
end
