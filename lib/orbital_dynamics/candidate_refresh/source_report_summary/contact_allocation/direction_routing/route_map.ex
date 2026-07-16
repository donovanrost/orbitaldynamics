defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.DirectionRouting.RouteMap do
  @moduledoc false

  alias __MODULE__.{EntryFields, FieldMaps}

  def route_values(fields) do
    field_maps = FieldMaps.from_fields(fields)

    field_maps
    |> FieldMaps.route_keys()
    |> Map.new(fn direction ->
      {direction, EntryFields.route_entry(direction, field_maps)}
    end)
    |> non_empty_map()
  end

  defp non_empty_map(map) when map_size(map) == 0, do: nil
  defp non_empty_map(map), do: map
end
