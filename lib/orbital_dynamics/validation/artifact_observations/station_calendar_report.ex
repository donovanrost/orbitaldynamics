defmodule OrbitalDynamics.Validation.ArtifactObservations.StationCalendarReport do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)
    affected_contacts = Map.get(artifact, "affected_contacts") || []

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "model" => Map.get(artifact, "model"),
      "input_contact_count" => Map.get(artifact, "input_contact_count"),
      "calendar_entry_count" => Map.get(artifact, "calendar_entry_count"),
      "affected_contact_count" => Map.get(artifact, "affected_contact_count"),
      "affected_duration_s" => Map.get(artifact, "affected_duration_s"),
      "provider_calendar_contention_group_count" =>
        Map.get(artifact, "provider_calendar_contention_group_count"),
      "duplicate_affected_contact_id_count" =>
        Map.get(artifact, "duplicate_affected_contact_id_count"),
      "duplicate_affected_contact_row_count" =>
        Map.get(artifact, "duplicate_affected_contact_row_count"),
      "affected_contact_ground_station_counts" =>
        Map.get(artifact, "affected_contact_ground_station_counts") || %{},
      "row_derived_affected_contact_ground_station_counts" =>
        row_value_counts(affected_contacts, "ground_station_id"),
      "affected_contact_availability_counts" =>
        Map.get(artifact, "affected_contact_availability_counts") || %{},
      "row_derived_affected_contact_availability_counts" =>
        row_value_counts(affected_contacts, "station_availability"),
      "direction_counts" => Map.get(artifact, "direction_counts") || %{},
      "row_derived_direction_counts" => row_value_counts(affected_contacts, "direction"),
      "station_calendar_status_counts" =>
        Map.get(artifact, "station_calendar_status_counts") || %{},
      "row_derived_station_calendar_status_counts" =>
        row_value_counts(affected_contacts, "station_calendar_status"),
      "station_reservation_match_status_counts" =>
        Map.get(artifact, "station_reservation_match_status_counts") || %{},
      "row_derived_station_reservation_match_status_counts" =>
        row_value_counts(affected_contacts, "station_reservation_match_status"),
      "stale_reservation_hold_count" => stale_reservation_hold_count(affected_contacts),
      "row_derived_stale_reservation_hold_count" =>
        stale_reservation_hold_count(affected_contacts),
      "reservation_hold_status_count" => reservation_hold_status_count(affected_contacts),
      "row_derived_reservation_hold_status_count" =>
        reservation_hold_status_count(affected_contacts),
      "row_derived_affected_contact_count" => length(affected_contacts),
      "row_derived_affected_duration_s" => sum_numeric(affected_contacts, "overlap_duration_s"),
      "row_derived_contact_ids_by_station_reservation_match_status" =>
        affected_contacts
        |> group_row_ids_by_present_value("station_reservation_match_status", "contact_id")
        |> sort_grouped_values(),
      "provider_reservation_execution_boundary" =>
        get_in(artifact, ["assumptions", "execution_boundary"])
    }
  end

  defp group_row_ids_by_present_value(rows, value_key, id_key) do
    rows
    |> Enum.reject(&(Map.get(&1, value_key) == nil))
    |> Enum.group_by(&Map.get(&1, value_key), &Map.get(&1, id_key))
    |> Map.new(fn {value, ids} ->
      {to_string(value), Enum.reject(ids, &is_nil/1)}
    end)
  end

  defp row_value_counts(rows, key) when is_list(rows) do
    rows
    |> Enum.map(&Map.get(&1, key))
    |> Enum.reject(&is_nil/1)
    |> Enum.frequencies()
    |> Map.new(fn {value, count} -> {to_string(value), count} end)
  end

  defp sort_grouped_values(grouped_values) do
    Map.new(grouped_values, fn {key, values} -> {key, Enum.sort(values)} end)
  end

  defp sum_numeric(rows, key) do
    rows
    |> Enum.map(&Map.get(&1, key))
    |> Enum.filter(&is_number/1)
    |> Enum.sum()
  end

  defp stale_reservation_hold_count(affected_contacts) when is_list(affected_contacts) do
    Enum.count(affected_contacts, fn contact ->
      starts_at_s = Map.get(contact, "starts_at_s")
      expires_at_s = Map.get(contact, "station_reservation_expires_at_s")

      is_number(starts_at_s) and is_number(expires_at_s) and expires_at_s < starts_at_s and
        Map.get(contact, "station_reservation_status") == "tentative_hold"
    end)
  end

  defp reservation_hold_status_count(affected_contacts) when is_list(affected_contacts) do
    Enum.count(
      affected_contacts,
      &(Map.get(&1, "station_reservation_status") == "tentative_hold")
    )
  end

  defp stringify_keys(%{} = map) do
    Map.new(map, fn
      {key, value} when is_atom(key) -> {Atom.to_string(key), stringify_keys(value)}
      {key, value} when is_binary(key) -> {key, stringify_keys(value)}
      {key, value} -> {key, stringify_keys(value)}
    end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)

  defp stringify_keys(value), do: value
end
