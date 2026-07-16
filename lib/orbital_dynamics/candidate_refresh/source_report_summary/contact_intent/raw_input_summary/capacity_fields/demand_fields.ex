defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.RawInputSummary.CapacityFields.DemandFields do
  @moduledoc false

  alias __MODULE__.DirectionFields

  def fields(capacity_pack_demand) do
    %{
      "capacity_pack_required_contact_count" =>
        capacity_pack_demand["capacity_pack_required_contact_count"],
      "capacity_pack_required_capacity_fraction" =>
        capacity_pack_demand["capacity_pack_required_capacity_fraction"],
      "capacity_pack_required_capacity_fraction_by_ground_station" =>
        capacity_pack_demand["capacity_pack_required_capacity_fraction_by_ground_station_id"],
      "capacity_pack_required_capacity_fraction_by_direction" =>
        capacity_pack_demand["capacity_pack_required_capacity_fraction_by_direction"],
      "capacity_pack_required_capacity_fraction_by_direction_and_ground_station" =>
        capacity_pack_demand[
          "capacity_pack_required_capacity_fraction_by_direction_and_ground_station_id"
        ],
      "required_capacity_fraction_source_counts" =>
        capacity_pack_demand["required_capacity_fraction_source_counts"],
      "required_capacity_fraction_contact_ids_by_source" =>
        capacity_pack_demand["required_capacity_fraction_contact_ids_by_source"]
    }
    |> Map.merge(DirectionFields.fields(capacity_pack_demand))
  end
end
