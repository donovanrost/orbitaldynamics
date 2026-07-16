defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.CompactSummary.DirectionFields.RoutingFields do
  @moduledoc false

  alias __MODULE__.DerivedFields

  def fields(summaries, aggregates) do
    %{
      "capacity_pack_required_capacity_fraction_by_direction" => aggregates.required_by_direction,
      "capacity_pack_required_capacity_fraction_by_direction_and_ground_station" =>
        aggregates.required_by_direction_and_station,
      "capacity_pack_contact_ids_by_direction" => aggregates.capacity_contact_ids_by_direction,
      "capacity_pack_contact_ids_by_direction_and_ground_station" =>
        aggregates.capacity_contact_ids_by_direction_and_station,
      "contact_ids_by_direction_and_ground_station" =>
        aggregates.contact_ids_by_direction_and_station,
      "direction_counts" => aggregates.direction_counts,
      "contact_ids_by_direction" => aggregates.contact_ids_by_direction
    }
    |> Map.merge(DerivedFields.fields(summaries, aggregates))
  end
end
