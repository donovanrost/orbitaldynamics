defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.DirectionRouting.RouteMap.EntryFields.DirectFields do
  @moduledoc false

  def fields(direction, field_maps) do
    %{
      "contact_count" => field_value(field_maps, :direction_counts, direction),
      "contact_ids" => field_value(field_maps, :contact_ids_by_direction, direction, []),
      "station_pressure_contact_count" =>
        field_value(field_maps, :station_pressure_direction_counts, direction),
      "station_pressure_contact_ids" =>
        field_value(
          field_maps,
          :station_pressure_contact_ids_by_direction,
          direction,
          []
        ),
      "reservation_conflict_contact_count" =>
        field_value(field_maps, :reservation_conflict_direction_counts, direction),
      "reservation_conflict_contact_ids" =>
        field_value(
          field_maps,
          :reservation_conflict_contact_ids_by_direction,
          direction,
          []
        )
    }
  end

  defp field_value(field_maps, field_name, direction, default \\ nil) do
    field_maps
    |> Map.fetch!(field_name)
    |> Map.get(direction, default)
  end
end
