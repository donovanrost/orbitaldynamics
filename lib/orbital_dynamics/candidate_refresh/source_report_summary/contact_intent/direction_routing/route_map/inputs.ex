defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.DirectionRouting.RouteMap.Inputs do
  @moduledoc false

  alias __MODULE__.NormalizedInputs

  def normalize(
        direction_counts,
        contact_ids_by_direction,
        required_capacity_by_direction,
        capacity_contact_ids_by_direction,
        contact_ids_by_direction_and_station,
        required_capacity_by_direction_and_station,
        capacity_contact_ids_by_direction_and_station
      ) do
    NormalizedInputs.normalize(
      direction_counts,
      contact_ids_by_direction,
      required_capacity_by_direction,
      capacity_contact_ids_by_direction,
      contact_ids_by_direction_and_station,
      required_capacity_by_direction_and_station,
      capacity_contact_ids_by_direction_and_station
    )
  end

  def directions(inputs) do
    NormalizedInputs.directions(inputs)
  end
end
