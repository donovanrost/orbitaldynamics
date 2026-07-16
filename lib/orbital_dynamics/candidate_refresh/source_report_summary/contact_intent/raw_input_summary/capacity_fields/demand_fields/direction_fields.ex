defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.RawInputSummary.CapacityFields.DemandFields.DirectionFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.DirectionRouting

  def fields(capacity_pack_demand) do
    %{
      "capacity_pack_contact_ids_by_ground_station" =>
        DirectionRouting.map_value_lists(
          capacity_pack_demand["capacity_pack_contact_ids_by_ground_station_id"]
        ),
      "contact_ids_by_ground_station" =>
        DirectionRouting.map_value_lists(capacity_pack_demand["contact_ids_by_ground_station_id"]),
      "capacity_pack_contact_ids_by_direction" =>
        DirectionRouting.map_value_lists(
          capacity_pack_demand["capacity_pack_contact_ids_by_direction"]
        ),
      "capacity_pack_contact_ids_by_direction_and_ground_station" =>
        DirectionRouting.nested_map_value_lists(
          capacity_pack_demand["capacity_pack_contact_ids_by_direction_and_ground_station_id"]
        ),
      "contact_ids_by_direction_and_ground_station" =>
        DirectionRouting.nested_map_value_lists(
          capacity_pack_demand["contact_ids_by_direction_and_ground_station_id"]
        )
    }
  end
end
