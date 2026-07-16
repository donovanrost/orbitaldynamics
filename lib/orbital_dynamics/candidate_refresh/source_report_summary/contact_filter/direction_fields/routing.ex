defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactFilter.DirectionFields.Routing do
  @moduledoc false

  alias __MODULE__.{ContactIds, DirectionNames}

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      compact_map: 1
    ]

  def keys(direction_counts, contact_ids_by_direction) do
    DirectionNames.values(direction_counts, contact_ids_by_direction)
    |> case do
      [] -> nil
      directions -> directions
    end
  end

  def values(direction_counts, contact_ids_by_direction) do
    direction_counts = direction_counts || %{}
    contact_ids_by_direction = ContactIds.normalized_map(contact_ids_by_direction) || %{}

    direction_counts
    |> DirectionNames.values(contact_ids_by_direction)
    |> Map.new(&route_pair(&1, direction_counts, contact_ids_by_direction))
    |> non_empty_map()
  end

  defp route_pair(direction, direction_counts, contact_ids_by_direction) do
    route =
      %{
        "contact_count" => Map.get(direction_counts, direction),
        "contact_ids" => Map.get(contact_ids_by_direction, direction, [])
      }
      |> compact_map()

    {direction, route}
  end

  defp non_empty_map(map) when map_size(map) == 0, do: nil
  defp non_empty_map(map), do: map
end
