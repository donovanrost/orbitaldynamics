defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.Summary.Relay do
  @moduledoc false

  def fields(link_summary) do
    %{
      "relay_route_count" => non_zero_count(summary_integer(link_summary, "relay_route_count")),
      "direct_downlink_route_count" =>
        non_zero_count(summary_integer(link_summary, "direct_downlink_route_count")),
      "relay_route_ids" => Map.get(link_summary, "relay_route_ids"),
      "source_spacecraft_ids" => Map.get(link_summary, "source_spacecraft_ids"),
      "relay_spacecraft_ids" => Map.get(link_summary, "relay_spacecraft_ids"),
      "ground_downlink_contact_ids" => Map.get(link_summary, "ground_downlink_contact_ids"),
      "relay_custody_status_counts" => Map.get(link_summary, "relay_custody_status_counts"),
      "relay_latency_status_counts" => Map.get(link_summary, "relay_latency_status_counts"),
      "relay_risk_status_counts" => Map.get(link_summary, "relay_risk_status_counts"),
      "relay_route_ids_by_custody_status" =>
        Map.get(link_summary, "relay_route_ids_by_custody_status"),
      "relay_route_ids_by_latency_status" =>
        Map.get(link_summary, "relay_route_ids_by_latency_status"),
      "relay_route_ids_by_risk_status" => Map.get(link_summary, "relay_route_ids_by_risk_status"),
      "relay_route_ids_by_ground_station" =>
        Map.get(link_summary, "relay_route_ids_by_ground_station")
    }
  end

  def pressure?(replay) do
    (replay["relay_route_count"] || 0) > 0 or
      (replay["direct_downlink_route_count"] || 0) > 0 or
      List.wrap(replay["relay_route_ids"]) != [] or
      List.wrap(replay["source_spacecraft_ids"]) != [] or
      List.wrap(replay["relay_spacecraft_ids"]) != [] or
      List.wrap(replay["ground_downlink_contact_ids"]) != [] or
      map_size(empty_map_if_nil(replay["relay_custody_status_counts"])) > 0 or
      map_size(empty_map_if_nil(replay["relay_latency_status_counts"])) > 0 or
      map_size(empty_map_if_nil(replay["relay_risk_status_counts"])) > 0 or
      map_size(empty_map_if_nil(replay["relay_route_ids_by_custody_status"])) > 0 or
      map_size(empty_map_if_nil(replay["relay_route_ids_by_latency_status"])) > 0 or
      map_size(empty_map_if_nil(replay["relay_route_ids_by_risk_status"])) > 0 or
      map_size(empty_map_if_nil(replay["relay_route_ids_by_ground_station"])) > 0
  end

  defp summary_integer(%{} = summary, field) do
    case Map.get(summary, field) do
      value when is_integer(value) ->
        value

      value when is_float(value) ->
        trunc(value)

      value when is_binary(value) ->
        case Integer.parse(String.trim(value)) do
          {integer, ""} -> integer
          _parse -> 0
        end

      _value ->
        0
    end
  end

  defp summary_integer(_summary, _field), do: 0

  defp non_zero_count(count) when is_integer(count) and count > 0, do: count
  defp non_zero_count(_count), do: nil

  defp empty_map_if_nil(%{} = map), do: map
  defp empty_map_if_nil(_map), do: %{}
end
