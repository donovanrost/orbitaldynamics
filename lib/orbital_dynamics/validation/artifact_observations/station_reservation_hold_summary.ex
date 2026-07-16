defmodule OrbitalDynamics.Validation.ArtifactObservations.StationReservationHoldSummary do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)
    rows = map_rows(artifact, "review_rows")

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "model" => Map.get(artifact, "model"),
      "source_artifact_type" => Map.get(artifact, "source_artifact_type"),
      "source" => Map.get(artifact, "source"),
      "reservation_hold_count" => Map.get(artifact, "reservation_hold_count"),
      "affected_contact_reservation_hold_count" =>
        Map.get(artifact, "affected_contact_reservation_hold_count"),
      "provider_calendar_contention_hold_count" =>
        Map.get(artifact, "provider_calendar_contention_hold_count"),
      "reservation_hold_review_status" => Map.get(artifact, "reservation_hold_review_status"),
      "reservation_hold_status_counts" =>
        Map.get(artifact, "reservation_hold_status_counts") || %{},
      "row_derived_reservation_hold_status_counts" =>
        rows
        |> Enum.flat_map(&list_values(&1, "reservation_statuses"))
        |> list_value_counts(),
      "reservation_hold_expiration_status_counts" =>
        Map.get(artifact, "reservation_hold_expiration_status_counts") || %{},
      "row_derived_reservation_hold_expiration_status_counts" =>
        count_rows_by_value(rows, "station_reservation_expiration_status"),
      "reservation_hold_id_keys" =>
        artifact
        |> list_values("reservation_hold_ids")
        |> stable_id_keys(),
      "row_derived_reservation_hold_id_keys" =>
        rows
        |> Enum.flat_map(&list_values(&1, "reservation_ids"))
        |> stable_id_keys(),
      "reservation_hold_ids_by_reserved_by" =>
        Map.get(artifact, "reservation_hold_ids_by_reserved_by") || %{},
      "row_derived_reservation_hold_ids_by_reserved_by" =>
        group_row_list_ids_by_list_value(rows, "reserved_by", "reservation_ids"),
      "reservation_hold_ids_by_row_type" =>
        Map.get(artifact, "reservation_hold_ids_by_row_type") || %{},
      "row_derived_reservation_hold_ids_by_row_type" =>
        group_row_list_ids_by_value(rows, "reservation_review_row_type", "reservation_ids"),
      "reservation_hold_contact_ids_by_expiration_status" =>
        Map.get(artifact, "reservation_hold_contact_ids_by_expiration_status") || %{},
      "row_derived_reservation_hold_contact_ids_by_expiration_status" =>
        rows
        |> group_row_ids_by_present_value("station_reservation_expiration_status", "contact_id")
        |> reject_empty_grouped_values()
        |> sort_grouped_values(),
      "earliest_reservation_hold_expires_at_s" =>
        Map.get(artifact, "earliest_reservation_hold_expires_at_s"),
      "execution_boundary" => get_in(artifact, ["assumptions", "execution_boundary"]),
      "operator_authority" => get_in(artifact, ["assumptions", "operator_authority"]),
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

  defp stable_id_keys(values) when is_list(values) do
    values
    |> Enum.map(&to_string/1)
    |> Enum.uniq()
    |> Enum.sort()
    |> Enum.join("|")
  end

  defp group_row_ids_by_present_value(rows, value_key, id_key) do
    rows
    |> Enum.reject(&(Map.get(&1, value_key) == nil))
    |> Enum.group_by(&Map.get(&1, value_key), &Map.get(&1, id_key))
    |> Map.new(fn {value, ids} ->
      {to_string(value), Enum.reject(ids, &is_nil/1)}
    end)
  end

  defp group_row_list_ids_by_value(rows, value_key, id_key) do
    rows
    |> Enum.group_by(&(Map.get(&1, value_key) || "unknown"), &List.wrap(Map.get(&1, id_key)))
    |> Map.new(fn {value, id_lists} ->
      ids =
        id_lists
        |> List.flatten()
        |> Enum.reject(&is_nil/1)
        |> Enum.map(&to_string/1)
        |> Enum.uniq()
        |> Enum.sort()

      {to_string(value), ids}
    end)
  end

  defp group_row_list_ids_by_list_value(rows, value_key, id_key) do
    rows
    |> Enum.flat_map(fn row ->
      values = list_values(row, value_key)
      ids = list_values(row, id_key)

      for value <- values, id <- ids, do: {to_string(value), to_string(id)}
    end)
    |> Enum.group_by(fn {value, _id} -> value end, fn {_value, id} -> id end)
    |> Map.new(fn {value, ids} ->
      {value, ids |> Enum.uniq() |> Enum.sort()}
    end)
  end

  defp sort_grouped_values(grouped_values) do
    Map.new(grouped_values, fn {key, values} -> {key, Enum.sort(values)} end)
  end

  defp reject_empty_grouped_values(grouped_values) do
    grouped_values
    |> Enum.reject(fn {_key, values} -> values == [] end)
    |> Map.new()
  end

  defp count_rows_by_value(rows, key) do
    rows
    |> Enum.map(&(Map.get(&1, key) || "unknown"))
    |> Enum.frequencies()
    |> Map.new(fn {value, count} -> {to_string(value), count} end)
  end

  defp list_value_counts(values) when is_list(values) do
    values
    |> Enum.frequencies()
    |> Map.new(fn {value, count} -> {to_string(value), count} end)
  end

  defp list_value_counts(_values), do: %{}

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
