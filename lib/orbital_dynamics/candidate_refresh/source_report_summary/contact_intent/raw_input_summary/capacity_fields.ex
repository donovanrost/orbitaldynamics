defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.RawInputSummary.CapacityFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.RawInputSummary.CapacityFields.DemandFields
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.DirectionRouting
  alias OrbitalDynamics.Communications.ContactIntent, as: CommunicationsContactIntent

  def fields(intents) do
    capacity_pack_demand = CommunicationsContactIntent.summary(intents)

    capacity_pack_demand
    |> DemandFields.fields()
    |> Map.merge(routing_fields(intents, capacity_pack_demand))
  end

  defp routing_fields(intents, capacity_pack_demand) do
    direction_counts = DirectionRouting.direction_counts(intents)
    contact_ids_by_direction = DirectionRouting.contact_ids_by_direction(intents)

    %{
      "directions" => DirectionRouting.direction_keys(contact_ids_by_direction),
      "direction_counts" => direction_counts,
      "contact_ids_by_direction" => contact_ids_by_direction,
      "direction_routing" =>
        DirectionRouting.build(
          direction_counts,
          contact_ids_by_direction,
          capacity_pack_demand["capacity_pack_required_capacity_fraction_by_direction"],
          capacity_pack_demand["capacity_pack_contact_ids_by_direction"],
          capacity_pack_demand["contact_ids_by_direction_and_ground_station_id"],
          capacity_pack_demand[
            "capacity_pack_required_capacity_fraction_by_direction_and_ground_station_id"
          ],
          capacity_pack_demand["capacity_pack_contact_ids_by_direction_and_ground_station_id"]
        )
    }
  end
end
