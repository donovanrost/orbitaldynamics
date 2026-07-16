defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactContention.DirectionRouting.RouteMap do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [compact_map: 1]

  def field(direction_counts, contact_ids_by_direction) do
    direction_counts = empty_map_if_nil(direction_counts)
    contact_ids_by_direction = empty_map_if_nil(contact_ids_by_direction)

    [
      Map.keys(direction_counts),
      Map.keys(contact_ids_by_direction)
    ]
    |> List.flatten()
    |> Enum.map(&to_string/1)
    |> Enum.uniq()
    |> Enum.sort()
    |> Map.new(fn direction ->
      route =
        %{
          "contact_count" => Map.get(direction_counts, direction),
          "contact_ids" => Map.get(contact_ids_by_direction, direction, [])
        }
        |> compact_map()

      {direction, route}
    end)
    |> non_empty_map()
  end

  defp empty_map_if_nil(%{} = map), do: map
  defp empty_map_if_nil(_map), do: %{}

  defp non_empty_map(map) when map_size(map) == 0, do: nil
  defp non_empty_map(map), do: map
end
