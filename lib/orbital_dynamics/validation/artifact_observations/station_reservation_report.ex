defmodule OrbitalDynamics.Validation.ArtifactObservations.StationReservationReport do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)
    affected_contacts = map_rows(artifact, "affected_contacts")

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "model" => Map.get(artifact, "model"),
      "affected_contact_reservation_count" =>
        Map.get(artifact, "affected_contact_reservation_count"),
      "provider_calendar_contention_group_count" =>
        Map.get(artifact, "provider_calendar_contention_group_count"),
      "reservation_review_count" => Map.get(artifact, "reservation_review_count"),
      "reservation_review_status" => Map.get(artifact, "reservation_review_status"),
      "station_reservation_match_status_counts" =>
        Map.get(artifact, "station_reservation_match_status_counts") || %{},
      "row_derived_station_reservation_match_status_counts" =>
        row_value_counts(affected_contacts, "station_reservation_match_status"),
      "reservation_status_counts" => Map.get(artifact, "reservation_status_counts") || %{},
      "row_derived_reservation_status_counts" =>
        station_reservation_status_counts(affected_contacts),
      "reservation_id_order" => artifact |> Map.get("reservation_ids", []) |> Enum.join("|"),
      "row_derived_reservation_id_order" =>
        affected_contacts
        |> station_reservation_ids()
        |> Enum.join("|"),
      "row_derived_reservation_ids_by_match_status" =>
        affected_contacts
        |> station_reservation_ids_by_match_status()
        |> sort_grouped_values(),
      "provider_reservation_execution_boundary" =>
        get_in(artifact, ["assumptions", "execution_boundary"])
    }
  end

  defp map_rows(map, key) do
    case Map.get(map, key) do
      rows when is_list(rows) -> Enum.filter(rows, &is_map/1)
      _rows -> []
    end
  end

  defp list_values(map, key) do
    case Map.get(map, key) do
      values when is_list(values) -> values
      _values -> []
    end
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

  defp list_value_counts(values) when is_list(values) do
    values
    |> Enum.frequencies()
    |> Map.new(fn {value, count} -> {to_string(value), count} end)
  end

  defp station_reservation_status_counts(affected_contacts) when is_list(affected_contacts) do
    affected_contacts
    |> Enum.flat_map(fn contact ->
      List.wrap(Map.get(contact, "station_reservation_status")) ++
        list_values(contact, "station_calendar_reservation_statuses")
    end)
    |> Enum.reject(&is_nil/1)
    |> list_value_counts()
  end

  defp station_reservation_ids(affected_contacts) when is_list(affected_contacts) do
    affected_contacts
    |> Enum.flat_map(fn contact ->
      List.wrap(Map.get(contact, "station_reservation_id")) ++
        list_values(contact, "station_calendar_reservation_ids")
    end)
    |> Enum.reject(&is_nil/1)
    |> Enum.map(&to_string/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp station_reservation_ids_by_match_status(affected_contacts)
       when is_list(affected_contacts) do
    affected_contacts
    |> Enum.reject(&(Map.get(&1, "station_reservation_match_status") == nil))
    |> Enum.group_by(
      &Map.get(&1, "station_reservation_match_status"),
      fn contact ->
        contact
        |> station_reservation_ids_from_contact()
        |> List.wrap()
      end
    )
    |> Map.new(fn {status, ids} ->
      {to_string(status), ids |> List.flatten() |> Enum.uniq()}
    end)
  end

  defp station_reservation_ids_from_contact(contact) do
    List.wrap(Map.get(contact, "station_reservation_id")) ++
      list_values(contact, "station_calendar_reservation_ids")
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
