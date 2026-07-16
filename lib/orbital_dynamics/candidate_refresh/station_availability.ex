defmodule OrbitalDynamics.CandidateRefresh.StationAvailability do
  @moduledoc false

  @unavailable_availability_aliases ["outage", "down", "offline"]
  @unavailable_station_tokens ["unavailable", "maintenance" | @unavailable_availability_aliases]

  def unavailable?(station, encode_value) do
    availability =
      station
      |> Map.get("availability")
      |> encode_value.()
      |> normalized_token()

    status =
      station
      |> Map.get("status")
      |> encode_value.()
      |> normalized_token()

    availability in @unavailable_station_tokens or
      status in @unavailable_station_tokens or
      Map.get(station, "available") == false
  end

  def reserved?(station, encode_value) do
    status =
      station
      |> Map.get("status")
      |> encode_value.()
      |> normalized_token()

    availability =
      station
      |> Map.get("availability")
      |> encode_value.()
      |> normalized_token()

    contention_status =
      station
      |> Map.get("station_contention_status")
      |> encode_value.()
      |> normalized_token()

    status == "reserved" or
      availability == "reserved" or
      contention_status == "reserved_overlap"
  end

  def availability(station, encode_value, station_capacity_fraction) do
    availability =
      station
      |> Map.get("availability")
      |> encode_value.()
      |> normalized_token()

    cond do
      availability in ["unavailable", "reserved", "reduced_capacity"] -> availability
      unavailable?(station, encode_value) -> "unavailable"
      reserved?(station, encode_value) -> "reserved"
      station_capacity_fraction.(station) < 1.0 -> "reduced_capacity"
      true -> "available"
    end
  end

  def normalized_token(value) when is_binary(value) do
    value
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r/[\s-]+/, "_")
    |> canonical_token()
  end

  def normalized_token(value), do: value

  def contention_status(station, encode_value) do
    Map.get(station, "station_contention_status") ||
      if reserved?(station, encode_value), do: "reserved_overlap", else: nil
  end

  def reservation_match_status(%{} = station, encode_value) do
    cond do
      non_empty?(Map.get(station, "station_reservation_match_status")) ->
        Map.get(station, "station_reservation_match_status")

      non_empty?(Map.get(station, "reservation_match_status")) ->
        Map.get(station, "reservation_match_status")

      contention_status(station, encode_value) == "reserved_overlap" ->
        reservation_overlap_match_status(station)

      true ->
        nil
    end
  end

  def reservation_overlap_match_status(station) do
    reservation_ids = Map.get(station, "station_calendar_reservation_ids", [])
    reservation_id = Map.get(station, "reservation_id")

    cond do
      non_empty?(reservation_id) -> "overlap"
      is_list(reservation_ids) and length(reservation_ids) == 1 -> "overlap"
      is_list(reservation_ids) and length(reservation_ids) > 1 -> "ambiguous"
      true -> nil
    end
  end

  defp canonical_token(value) when value in @unavailable_availability_aliases,
    do: "unavailable"

  defp canonical_token(value), do: value

  defp non_empty?(value), do: value not in [nil, ""]
end
