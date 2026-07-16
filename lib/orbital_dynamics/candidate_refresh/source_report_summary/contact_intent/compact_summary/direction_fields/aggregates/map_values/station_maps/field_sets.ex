defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.CompactSummary.DirectionFields.Aggregates.MapValues.StationMaps.FieldSets do
  @moduledoc false

  def compact do
    %{
      required_by_direction_and_station:
        "capacity_pack_required_capacity_fraction_by_direction_and_ground_station_id",
      contact_ids_by_direction_and_station: "contact_ids_by_direction_and_ground_station_id",
      capacity_contact_ids_by_direction_and_station:
        "capacity_pack_contact_ids_by_direction_and_ground_station_id"
    }
  end

  def input do
    %{
      required_by_direction_and_station:
        "capacity_pack_required_capacity_fraction_by_direction_and_ground_station",
      contact_ids_by_direction_and_station: "contact_ids_by_direction_and_ground_station",
      capacity_contact_ids_by_direction_and_station:
        "capacity_pack_contact_ids_by_direction_and_ground_station"
    }
  end
end
