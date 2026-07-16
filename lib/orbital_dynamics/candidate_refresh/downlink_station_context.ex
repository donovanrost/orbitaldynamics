defmodule OrbitalDynamics.CandidateRefresh.DownlinkStationContext do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.{
    StationAvailability,
    StationCapacity,
    StationProviderContention,
    StationThroughput,
    StationState
  }

  def build(
        refresh,
        ground_station_id,
        starts_at_s,
        ends_at_s,
        refresh_ground_network_fun,
        operational_feedback
      ) do
    station_state =
      StationState.state(
        refresh,
        ground_station_id,
        starts_at_s,
        ends_at_s,
        "downlink",
        refresh_ground_network_fun
      )

    declared_capacity_fraction = station_capacity_fraction(station_state)

    {station_throughput_factor, station_throughput_source} =
      StationThroughput.factor(
        refresh,
        ground_station_id,
        station_state,
        operational_feedback
      )

    capacity_fraction =
      (declared_capacity_fraction * station_throughput_factor)
      |> max(0.0)
      |> min(1.0)

    throughput_context =
      %{
        "station_capacity_fraction" => capacity_fraction,
        "declared_station_capacity_fraction" => declared_capacity_fraction,
        "station_throughput_factor" => station_throughput_factor,
        "station_throughput_factor_source" => station_throughput_source
      }

    station_context = station_context(station_state)

    {station_context, throughput_context, capacity_fraction}
  end

  defp station_context(station_state) do
    %{
      "station_availability" => station_availability(station_state),
      "station_contention_status" =>
        StationAvailability.contention_status(station_state, &encode_value/1),
      "station_calendar_entry_id" => StationState.calendar_entry_id(station_state),
      "station_calendar_provider_id" => StationState.calendar_provider_id(station_state),
      "station_calendar_provider_entry_id" =>
        StationState.calendar_provider_entry_id(station_state),
      "station_calendar_directions" => StationState.nonempty_directions(station_state),
      "station_calendar_status" => Map.get(station_state, "status"),
      "station_calendar_entry_ambiguous" =>
        Map.get(station_state, "station_calendar_entry_ambiguous"),
      "station_calendar_ambiguous_entry_count" =>
        Map.get(station_state, "station_calendar_ambiguous_entry_count"),
      "station_calendar_ambiguous_entry_ids" =>
        Map.get(station_state, "station_calendar_ambiguous_entry_ids"),
      "station_calendar_overlap_count" =>
        Map.get(station_state, "station_calendar_overlap_count"),
      "station_calendar_overlap_entry_ids" =>
        Map.get(station_state, "station_calendar_overlap_entry_ids"),
      "station_calendar_overlap_availabilities" =>
        Map.get(station_state, "station_calendar_overlap_availabilities"),
      "station_reservation_id" => Map.get(station_state, "reservation_id"),
      "station_reserved_by" => Map.get(station_state, "reserved_by"),
      "station_reservation_status" => Map.get(station_state, "reservation_status"),
      "station_reservation_expires_at_s" => station_reservation_expires_at_s(station_state),
      "station_reservation_match_status" =>
        StationAvailability.reservation_match_status(station_state, &encode_value/1),
      "station_calendar_reservation_overlap_count" =>
        Map.get(station_state, "station_calendar_reservation_overlap_count"),
      "station_calendar_reservation_ids" =>
        Map.get(station_state, "station_calendar_reservation_ids") ||
          StationProviderContention.values(
            station_state,
            "reservation_ids"
          ),
      "station_calendar_reserved_by" =>
        Map.get(station_state, "station_calendar_reserved_by") ||
          StationProviderContention.values(station_state, "reserved_by"),
      "station_calendar_reservation_statuses" =>
        Map.get(station_state, "station_calendar_reservation_statuses") ||
          StationProviderContention.values(
            station_state,
            "reservation_statuses"
          ),
      "station_calendar_reservation_expires_at_s" =>
        StationState.calendar_reservation_expires_at_s(station_state, &numeric_or_nil/1),
      "station_calendar_trust_boundary_status" =>
        Map.get(station_state, "station_calendar_trust_boundary_status"),
      "trust_boundary" => Map.get(station_state, "trust_boundary"),
      "provenance" => Map.get(station_state, "provenance"),
      "source_station_calendar_entry" => Map.get(station_state, "source_station_calendar_entry"),
      "source_station_calendar_overlaps" =>
        Map.get(station_state, "source_station_calendar_overlaps")
    }
  end

  defp station_availability(station_state) do
    StationAvailability.availability(
      station_state,
      &encode_value/1,
      &station_capacity_fraction/1
    )
  end

  defp station_capacity_fraction(station_state) do
    StationCapacity.fraction(station_state, &numeric_or_nil/1)
  end

  defp station_reservation_expires_at_s(station_state) do
    [
      Map.get(station_state, "station_reservation_expires_at_s"),
      Map.get(station_state, "reservation_expires_at_s"),
      Map.get(station_state, "reservation_hold_expires_at_s"),
      Map.get(station_state, "hold_expires_at_s"),
      Map.get(station_state, "expires_at_s"),
      Map.get(station_state, "expires_at"),
      get_in(station_state, ["source_station_calendar_entry", "station_reservation_expires_at_s"]),
      get_in(station_state, ["source_station_calendar_entry", "reservation_expires_at_s"]),
      get_in(station_state, ["source_station_calendar_entry", "reservation_hold_expires_at_s"]),
      get_in(station_state, ["source_station_calendar_entry", "hold_expires_at_s"]),
      get_in(station_state, ["source_station_calendar_entry", "expires_at_s"]),
      get_in(station_state, ["source_station_calendar_entry", "expires_at"])
    ]
    |> Enum.find_value(&numeric_or_nil/1)
  end

  defp numeric_or_nil(value) when is_number(value), do: value * 1.0

  defp numeric_or_nil(value) when is_binary(value) do
    case Float.parse(value) do
      {number, ""} -> number
      _parse_error -> nil
    end
  end

  defp numeric_or_nil(_value), do: nil

  defp encode_value(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), encode_value(value)} end)
  end

  defp encode_value(values) when is_list(values) do
    if Keyword.keyword?(values) do
      Map.new(values, fn {key, value} -> {encode_value(key), encode_value(value)} end)
    else
      Enum.map(values, &encode_value/1)
    end
  end

  defp encode_value(value) when is_tuple(value), do: value |> Tuple.to_list() |> encode_value()
  defp encode_value(nil), do: nil
  defp encode_value(value) when is_boolean(value), do: value
  defp encode_value(value) when is_atom(value), do: Atom.to_string(value)
  defp encode_value(value), do: value
end
