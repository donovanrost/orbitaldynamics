defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.DirectionRouting.RouteMap.Inputs.NormalizedInputs do
  @moduledoc false

  alias __MODULE__.DirectionKeys

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.DirectionRouting.ValueMaps

  def normalize(
        direction_counts,
        contact_ids_by_direction,
        required_capacity_by_direction,
        capacity_contact_ids_by_direction,
        contact_ids_by_direction_and_station,
        required_capacity_by_direction_and_station,
        capacity_contact_ids_by_direction_and_station
      ) do
    %{
      direction_counts: direction_counts || %{},
      contact_ids_by_direction: ValueMaps.map_value_lists(contact_ids_by_direction) || %{},
      required_capacity_by_direction:
        ValueMaps.normalize_numeric_map(required_capacity_by_direction) || %{},
      capacity_contact_ids_by_direction:
        ValueMaps.map_value_lists(capacity_contact_ids_by_direction) || %{},
      contact_ids_by_direction_and_station:
        ValueMaps.nested_map_value_lists(contact_ids_by_direction_and_station) || %{},
      required_capacity_by_direction_and_station:
        ValueMaps.nested_normalize_numeric_map(required_capacity_by_direction_and_station) || %{},
      capacity_contact_ids_by_direction_and_station:
        ValueMaps.nested_map_value_lists(capacity_contact_ids_by_direction_and_station) || %{}
    }
  end

  def directions(inputs) do
    DirectionKeys.from_inputs(inputs)
  end
end
