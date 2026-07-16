defmodule OrbitalDynamics.CandidateRefresh.ContactIntentStationFeedback do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.{StationAvailability, StationCapacity, ValueEncoding}

  def entries(source_contact_intents) do
    source_contact_intents
    |> Enum.map(fn {path, intent} -> ground_network_entry(path, intent) end)
    |> Enum.reject(&is_nil/1)
  end

  defp ground_network_entry(path, %{} = intent) do
    intent = stringify_keys(intent)
    ground_station_id = stable_id_or_nil(intent["ground_station_id"] || nested_station_id(intent))
    station_state = station_state(intent)

    with station_id when station_id not in [nil, ""] <- ground_station_id,
         %{} = station_state <- station_state do
      %{
        "id" => station_entry_id(path, intent),
        "ground_station_id" => station_id,
        "starts_at_s" => numeric_or_nil(intent["starts_at_s"]),
        "ends_at_s" => numeric_or_nil(intent["ends_at_s"]),
        "direction" => intent["direction"],
        "availability" => station_state["availability"],
        "status" => station_state["status"],
        "capacity_fraction" => station_state["capacity_fraction"],
        "station_calendar_entry_id" => stable_id_or_nil(intent["station_calendar_entry_id"]),
        "reservation_id" => stable_id_or_nil(intent["station_reservation_id"]),
        "reserved_by" => intent["station_reserved_by"],
        "reservation_status" => intent["station_reservation_status"],
        "station_contention_status" => intent["station_contention_status"],
        "source_contact_intent" => intent,
        "provenance" =>
          %{
            "source" => "contact_intent.v1",
            "source_path" => path,
            "trust_boundary" => trust_boundary(intent)
          }
          |> compact_map()
      }
      |> compact_map()
    else
      _value -> nil
    end
  end

  defp ground_network_entry(_path, _intent), do: nil

  defp stable_id_or_nil(value), do: ValueEncoding.stable_id_or_nil(value)

  defp station_state(%{} = intent) do
    availability =
      [
        intent["station_availability"],
        intent["station_calendar_status"],
        intent["availability"],
        intent["status"]
      ]
      |> Enum.find_value(fn value ->
        normalized =
          value
          |> ValueEncoding.encode_value_preserving_lists()
          |> StationAvailability.normalized_token()

        if normalized in ["unavailable", "maintenance", "reserved"], do: normalized
      end)

    capacity_fraction = station_capacity_fraction(intent)

    cond do
      availability in ["unavailable", "maintenance"] ->
        %{"availability" => "unavailable", "status" => "unavailable"}

      availability == "reserved" ->
        %{"availability" => "reserved", "status" => "reserved"}

      is_number(capacity_fraction) and capacity_fraction <= 0.0 ->
        %{"availability" => "reduced_capacity", "capacity_fraction" => 0.0}

      true ->
        nil
    end
  end

  defp station_capacity_fraction(station) do
    StationCapacity.fraction(station, &ValueEncoding.numeric_value/1)
  end

  defp trust_boundary(intent) do
    intent["trust_boundary"] ||
      intent["station_calendar_trust_boundary"] ||
      get_in(intent, ["provenance", "trust_boundary"]) ||
      get_in(intent, ["source_station_calendar_entry", "provenance", "trust_boundary"])
  end

  defp station_entry_id(path, intent) do
    base =
      stable_id_or_nil(intent["station_calendar_entry_id"]) ||
        stable_id_or_nil(intent["station_reservation_id"]) ||
        stable_id_or_nil(intent["id"]) ||
        stable_id_or_nil(intent["ground_station_id"]) ||
        "contact_intent_station_feedback"

    hash =
      :crypto.hash(:sha256, :erlang.term_to_binary({path, intent}))
      |> Base.encode16(case: :lower)
      |> binary_part(0, 8)

    ["contact_intent", base, hash]
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.join(":")
  end

  defp nested_station_id(candidate) do
    Enum.find_value(["ground_station", "station"], fn station_key ->
      case Map.get(candidate, station_key) do
        %{} = station ->
          Enum.find_value(["ground_station_id", "station_id", "id"], fn identity_key ->
            Map.get(station, identity_key)
          end)

        _station ->
          nil
      end
    end)
  end

  defp compact_map(map), do: ValueEncoding.compact_nil_values(map)
  defp stringify_keys(value), do: ValueEncoding.stringify_keys_preserving_lists(value)

  defp numeric_or_nil(value), do: ValueEncoding.numeric_value(value)
end
