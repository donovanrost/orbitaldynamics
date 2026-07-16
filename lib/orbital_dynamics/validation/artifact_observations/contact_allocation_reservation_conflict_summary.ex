defmodule OrbitalDynamics.Validation.ArtifactObservations.ContactAllocationReservationConflictSummary do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)
    rows = map_rows(artifact, "rows")
    conflict_rows = map_rows(artifact, "reservation_conflict_rows")
    review_rows = map_rows(artifact, "reservation_review_rows")
    reservation_rows = Enum.reject(rows, &(Map.get(&1, "station_reservation_id") == nil))

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "model" => Map.get(artifact, "model"),
      "source_artifact_type" => Map.get(artifact, "source_artifact_type"),
      "source" => Map.get(artifact, "source"),
      "input_contact_count" => Map.get(artifact, "input_contact_count"),
      "row_derived_input_contact_count" => length(rows),
      "station_reservation_contact_count" =>
        Map.get(artifact, "station_reservation_contact_count"),
      "row_derived_station_reservation_contact_count" => length(reservation_rows),
      "reservation_conflict_contact_count" =>
        Map.get(artifact, "reservation_conflict_contact_count"),
      "row_derived_reservation_conflict_contact_count" => length(conflict_rows),
      "reservation_review_contact_count" => Map.get(artifact, "reservation_review_contact_count"),
      "row_derived_reservation_review_contact_count" => length(review_rows),
      "station_reservation_match_status_counts" =>
        Map.get(artifact, "station_reservation_match_status_counts"),
      "row_derived_station_reservation_match_status_counts" =>
        row_value_counts(reservation_rows, "station_reservation_match_status"),
      "reservation_conflict_match_status_counts" =>
        Map.get(artifact, "reservation_conflict_match_status_counts"),
      "row_derived_reservation_conflict_match_status_counts" =>
        row_value_counts(conflict_rows, "station_reservation_match_status"),
      "station_reservation_status_counts" =>
        Map.get(artifact, "station_reservation_status_counts"),
      "row_derived_station_reservation_status_counts" =>
        row_value_counts(reservation_rows, "station_reservation_status"),
      "station_reserved_by_counts" => Map.get(artifact, "station_reserved_by_counts"),
      "row_derived_station_reserved_by_counts" =>
        row_value_counts(reservation_rows, "station_reserved_by"),
      "station_reservation_ids" => Map.get(artifact, "station_reservation_ids"),
      "station_reservation_keys" =>
        artifact
        |> list_values("station_reservation_ids")
        |> Enum.join("|"),
      "row_derived_station_reservation_ids" =>
        unique_row_values(reservation_rows, "station_reservation_id"),
      "row_derived_station_reservation_keys" =>
        reservation_rows
        |> unique_row_values("station_reservation_id")
        |> Enum.join("|"),
      "reservation_conflict_contact_ids" => Map.get(artifact, "reservation_conflict_contact_ids"),
      "reservation_conflict_contact_keys" =>
        artifact
        |> list_values("reservation_conflict_contact_ids")
        |> Enum.join("|"),
      "row_derived_reservation_conflict_contact_ids" =>
        unique_row_values(conflict_rows, "contact_id"),
      "row_derived_reservation_conflict_contact_keys" =>
        conflict_rows
        |> unique_row_values("contact_id")
        |> Enum.join("|"),
      "reservation_review_contact_ids" => Map.get(artifact, "reservation_review_contact_ids"),
      "reservation_review_contact_keys" =>
        artifact
        |> list_values("reservation_review_contact_ids")
        |> Enum.join("|"),
      "row_derived_reservation_review_contact_ids" =>
        unique_row_values(review_rows, "contact_id"),
      "row_derived_reservation_review_contact_keys" =>
        review_rows
        |> unique_row_values("contact_id")
        |> Enum.join("|"),
      "station_reservation_contact_ids_by_match_status" =>
        Map.get(artifact, "station_reservation_contact_ids_by_match_status"),
      "row_derived_station_reservation_contact_ids_by_match_status" =>
        reservation_rows
        |> group_row_ids_by_value("station_reservation_match_status", "contact_id")
        |> sort_grouped_values(),
      "reservation_conflict_contact_ids_by_match_status" =>
        Map.get(artifact, "reservation_conflict_contact_ids_by_match_status"),
      "row_derived_reservation_conflict_contact_ids_by_match_status" =>
        conflict_rows
        |> group_row_ids_by_value("station_reservation_match_status", "contact_id")
        |> sort_grouped_values(),
      "reservation_conflict_contact_ids_by_direction_and_ground_station_id" =>
        Map.get(artifact, "reservation_conflict_contact_ids_by_direction_and_ground_station_id"),
      "row_derived_reservation_conflict_contact_ids_by_direction_and_ground_station_id" =>
        contact_ids_by_direction_and_ground_station_id(conflict_rows),
      "station_reservation_ids_by_expiration_status" =>
        Map.get(artifact, "station_reservation_ids_by_expiration_status"),
      "model_limit_count" => count(artifact, "model_limits")
    }
  end

  defp count(map, key) do
    case Map.get(map, key) do
      values when is_list(values) -> length(values)
      _value -> 0
    end
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

  defp unique_row_values(rows, key) do
    rows
    |> Enum.map(&Map.get(&1, key))
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp group_row_ids_by_value(rows, value_key, id_key) do
    rows
    |> Enum.group_by(
      &(Map.get(&1, value_key) || "unknown"),
      &Map.get(&1, id_key)
    )
    |> Map.new(fn {value, ids} ->
      {to_string(value), Enum.reject(ids, &is_nil/1)}
    end)
  end

  defp contact_ids_by_direction_and_ground_station_id(rows) do
    rows
    |> Enum.reject(&(Map.get(&1, "direction") == nil or Map.get(&1, "ground_station_id") == nil))
    |> Enum.group_by(&Map.get(&1, "direction"))
    |> Map.new(fn {direction, direction_rows} ->
      ground_station_map =
        direction_rows
        |> group_row_ids_by_value("ground_station_id", "contact_id")
        |> sort_grouped_values()

      {to_string(direction), ground_station_map}
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
