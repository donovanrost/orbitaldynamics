defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.CompactSummary.ContactCounts.SourceContactIds.FieldSets do
  @moduledoc false

  def contact_count_fields do
    %{
      flat: [
        "contact_ids_by_direction",
        "contact_ids_by_ground_station_id",
        "contact_ids_by_ground_station"
      ],
      nested: [
        "contact_ids_by_direction_and_ground_station_id",
        "contact_ids_by_direction_and_ground_station"
      ]
    }
  end

  def capacity_pack_contact_count_fields do
    %{
      flat: [
        "capacity_pack_contact_ids_by_direction",
        "capacity_pack_contact_ids_by_ground_station_id",
        "capacity_pack_contact_ids_by_ground_station",
        "required_capacity_fraction_contact_ids_by_source"
      ],
      nested: [
        "capacity_pack_contact_ids_by_direction_and_ground_station_id",
        "capacity_pack_contact_ids_by_direction_and_ground_station"
      ]
    }
  end
end
