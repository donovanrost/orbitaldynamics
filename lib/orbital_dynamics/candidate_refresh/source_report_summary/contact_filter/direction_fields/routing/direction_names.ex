defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactFilter.DirectionFields.Routing.DirectionNames do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [sorted_string_values: 1]

  def values(direction_counts, contact_ids_by_direction) do
    [
      map_keys(direction_counts),
      map_keys(contact_ids_by_direction)
    ]
    |> List.flatten()
    |> sorted_string_values()
  end

  defp map_keys(%{} = map), do: Map.keys(map)
  defp map_keys(_map), do: []
end
