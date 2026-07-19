defmodule OrbitalDynamics.Study.Manifest.GroundNetworkInput do
  @moduledoc false

  alias OrbitalDynamics.Study.Manifest.InputField

  def campaign(campaign) do
    with {:ok, entries} <- InputField.optional_list(campaign, "ground_network") do
      parse(entries, "campaign.ground_network")
    end
  end

  def parse(entries, field) do
    entries
    |> Enum.reduce_while({:ok, []}, fn entry, {:ok, acc} ->
      case entry(entry, field) do
        {:ok, normalized} -> {:cont, {:ok, acc ++ [normalized]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp entry(%{} = entry, field) do
    with {:ok, ground_station_id} <- required_ground_station_id(entry),
         {:ok, id} <- InputField.optional_string(entry, "id"),
         {:ok, status} <- InputField.optional_string(entry, "status"),
         {:ok, availability} <- InputField.optional_station_availability(entry, "availability"),
         {:ok, starts_at_s} <- InputField.optional_number(entry, "starts_at_s"),
         {:ok, ends_at_s} <- InputField.optional_number(entry, "ends_at_s"),
         {:ok, capacity_fraction} <- InputField.optional_number(entry, "capacity_fraction"),
         {:ok, available?} <- InputField.optional_boolean_or_nil(entry, "available"),
         {:ok, station_calendar_entry_id} <-
           InputField.optional_string(entry, "station_calendar_entry_id"),
         {:ok, station_calendar_provider_id} <-
           InputField.optional_string(entry, "station_calendar_provider_id"),
         {:ok, station_calendar_provider_entry_id} <-
           InputField.optional_string(entry, "station_calendar_provider_entry_id"),
         {:ok, station_calendar_directions} <-
           InputField.optional_identifier_list(entry, "station_calendar_directions"),
         {:ok, station_calendar_status} <-
           InputField.optional_string(entry, "station_calendar_status"),
         {:ok, station_calendar_trust_boundary_status} <-
           InputField.optional_string(entry, "station_calendar_trust_boundary_status"),
         {:ok, station_contention_status} <-
           InputField.optional_string(entry, "station_contention_status"),
         {:ok, reservation_id} <- InputField.optional_string(entry, "reservation_id"),
         {:ok, reserved_by} <- InputField.optional_string(entry, "reserved_by"),
         {:ok, reservation_status} <- InputField.optional_string(entry, "reservation_status"),
         {:ok, station_reservation_match_status} <-
           InputField.optional_string(entry, "station_reservation_match_status"),
         {:ok, provenance} <- InputField.optional_map(entry, "provenance"),
         :ok <- InputField.validate_optional_interval(field, starts_at_s, ends_at_s) do
      capacity_fraction = capacity_fraction || numeric_availability_fraction(availability)
      status = ground_network_status(status, availability)
      availability = normalized_ground_network_availability(availability)

      {:ok,
       %{}
       |> Map.put("ground_station_id", ground_station_id)
       |> maybe_put("id", id)
       |> Map.put("status", status)
       |> maybe_put("availability", availability)
       |> maybe_put("starts_at_s", starts_at_s)
       |> maybe_put("ends_at_s", ends_at_s)
       |> maybe_put("capacity_fraction", capacity_fraction)
       |> maybe_put("available", available?)
       |> maybe_put("station_calendar_entry_id", station_calendar_entry_id)
       |> maybe_put("station_calendar_provider_id", station_calendar_provider_id)
       |> maybe_put("station_calendar_provider_entry_id", station_calendar_provider_entry_id)
       |> maybe_put_non_empty("station_calendar_directions", station_calendar_directions)
       |> maybe_put("station_calendar_status", station_calendar_status)
       |> maybe_put(
         "station_calendar_trust_boundary_status",
         station_calendar_trust_boundary_status
       )
       |> maybe_put("station_contention_status", station_contention_status)
       |> maybe_put("reservation_id", reservation_id)
       |> maybe_put("reserved_by", reserved_by)
       |> maybe_put("reservation_status", reservation_status)
       |> maybe_put("station_reservation_match_status", station_reservation_match_status)
       |> maybe_put("provenance", provenance)}
    end
  end

  defp entry(_entry, field), do: {:error, {:invalid_field, field}}

  defp ground_network_status(status, _availability) when is_binary(status), do: status

  defp ground_network_status(nil, availability) when is_number(availability) do
    if availability < 1.0, do: "reduced_capacity", else: "available"
  end

  defp ground_network_status(nil, availability) when is_binary(availability), do: availability
  defp ground_network_status(nil, _availability), do: "available"

  defp normalized_ground_network_availability(value) when is_number(value) do
    if value < 1.0, do: "reduced_capacity", else: "available"
  end

  defp normalized_ground_network_availability(value) when is_binary(value), do: value
  defp normalized_ground_network_availability(_value), do: nil

  defp numeric_availability_fraction(value) when is_number(value), do: value
  defp numeric_availability_fraction(_value), do: nil

  defp required_ground_station_id(entry) do
    case Map.get(entry, "ground_station_id") || Map.get(entry, "station_id") do
      value when value not in [nil, ""] -> {:ok, value}
      _missing -> {:error, {:missing_field, "ground_station_id"}}
    end
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp maybe_put_non_empty(map, _key, []), do: map
  defp maybe_put_non_empty(map, key, value), do: maybe_put(map, key, value)
end
