defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.DirectionRouting.RouteMap do
  @moduledoc false

  alias __MODULE__.EntryFields
  alias __MODULE__.Inputs

  def build(
        direction_counts,
        contact_ids_by_direction,
        required_capacity_by_direction,
        capacity_contact_ids_by_direction,
        contact_ids_by_direction_and_station,
        required_capacity_by_direction_and_station,
        capacity_contact_ids_by_direction_and_station
      ) do
    inputs =
      Inputs.normalize(
        direction_counts,
        contact_ids_by_direction,
        required_capacity_by_direction,
        capacity_contact_ids_by_direction,
        contact_ids_by_direction_and_station,
        required_capacity_by_direction_and_station,
        capacity_contact_ids_by_direction_and_station
      )

    inputs
    |> Inputs.directions()
    |> Map.new(fn direction ->
      {direction, EntryFields.route(direction, inputs)}
    end)
    |> non_empty_map()
  end

  defp non_empty_map(map) when map_size(map) == 0, do: nil
  defp non_empty_map(map), do: map
end
