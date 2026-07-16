defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.DirectionRouting.ContactIdMaps do
  @moduledoc false

  def contact_ids(direction_routing, contact_ids_field) do
    direction_routing
    |> Map.values()
    |> Enum.flat_map(fn
      %{} = route -> route |> Map.get(contact_ids_field, []) |> list_values()
      _route -> []
    end)
  end

  def string_list_map_counts(list_map) do
    list_map
    |> Enum.map(fn {key, values} -> {key, length(list_values(values))} end)
    |> Enum.reject(fn {_key, count} -> count == 0 end)
    |> Map.new()
    |> non_empty_map()
  end

  defp list_values(values) when is_list(values), do: values
  defp list_values(_values), do: []

  defp non_empty_map(map) when map_size(map) == 0, do: nil
  defp non_empty_map(map), do: map
end
