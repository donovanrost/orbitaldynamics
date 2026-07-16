defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.DirectionRouting.RouteMap.EntryFields do
  @moduledoc false

  def route(direction, inputs) do
    %{
      "contact_count" => Map.get(inputs.direction_counts, direction),
      "contact_ids" => Map.get(inputs.contact_ids_by_direction, direction, []),
      "capacity_pack_required_capacity_fraction" =>
        Map.get(inputs.required_capacity_by_direction, direction),
      "capacity_pack_contact_ids" =>
        Map.get(inputs.capacity_contact_ids_by_direction, direction, []),
      "ground_station_ids" => ground_station_ids(direction, inputs),
      "contact_ids_by_ground_station" =>
        Map.get(inputs.contact_ids_by_direction_and_station, direction, %{}),
      "capacity_pack_required_capacity_fraction_by_ground_station" =>
        Map.get(inputs.required_capacity_by_direction_and_station, direction, %{}),
      "capacity_pack_contact_ids_by_ground_station" =>
        Map.get(inputs.capacity_contact_ids_by_direction_and_station, direction, %{})
    }
    |> Enum.reject(fn
      {"capacity_pack_contact_ids", []} -> false
      {_key, value} when value in [nil, %{}, []] -> true
      _entry -> false
    end)
    |> Map.new()
  end

  defp ground_station_ids(direction, inputs) do
    inputs.contact_ids_by_direction_and_station
    |> Map.get(direction, %{})
    |> Map.keys()
    |> Enum.sort()
  end
end
