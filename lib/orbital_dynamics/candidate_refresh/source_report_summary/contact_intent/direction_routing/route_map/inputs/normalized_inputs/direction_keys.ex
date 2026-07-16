defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.DirectionRouting.RouteMap.Inputs.NormalizedInputs.DirectionKeys do
  @moduledoc false

  def from_inputs(inputs) do
    inputs
    |> key_lists()
    |> List.flatten()
    |> Enum.map(&to_string/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp key_lists(inputs) do
    [
      Map.keys(inputs.direction_counts),
      Map.keys(inputs.contact_ids_by_direction),
      Map.keys(inputs.required_capacity_by_direction),
      Map.keys(inputs.capacity_contact_ids_by_direction),
      Map.keys(inputs.contact_ids_by_direction_and_station),
      Map.keys(inputs.required_capacity_by_direction_and_station),
      Map.keys(inputs.capacity_contact_ids_by_direction_and_station)
    ]
  end
end
