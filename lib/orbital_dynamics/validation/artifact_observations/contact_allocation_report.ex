defmodule OrbitalDynamics.Validation.ArtifactObservations.ContactAllocationReport do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)
    rows = map_rows(artifact, "rows")
    reduced_capacity_pack_groups = map_rows(artifact, "reduced_capacity_pack_groups")
    resource_blocked_rows = Enum.filter(rows, &Map.has_key?(&1, "source_resource_suppression"))

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "model" => Map.get(artifact, "model"),
      "input_contact_count" => Map.get(artifact, "input_contact_count"),
      "row_derived_input_contact_count" => length(rows),
      "row_count" => length(rows),
      "allocated_contact_count" => Map.get(artifact, "allocated_contact_count"),
      "row_derived_allocated_contact_count" =>
        count_rows_matching(rows, "allocation_status", "allocated"),
      "returned_allocated_contact_count" => Map.get(artifact, "returned_allocated_contact_count"),
      "row_derived_returned_allocated_contact_count" =>
        count_rows_matching(rows, "effective_allocation_status", "allocated"),
      "deferred_contact_count" => Map.get(artifact, "deferred_contact_count"),
      "row_derived_deferred_contact_count" =>
        count_rows_matching(rows, "allocation_status", "deferred"),
      "blocked_contact_count" => Map.get(artifact, "blocked_contact_count"),
      "row_derived_blocked_contact_count" =>
        count_rows_matching(rows, "allocation_status", "blocked"),
      "policy_blocked_allocated_contact_count" =>
        Map.get(artifact, "policy_blocked_allocated_contact_count"),
      "row_derived_policy_blocked_allocated_contact_count" =>
        count_rows_matching(rows, "effective_allocation_status", "policy_blocked"),
      "invalid_contact_input_count" => Map.get(artifact, "invalid_contact_input_count"),
      "row_derived_invalid_contact_input_count" =>
        count_rows_matching(rows, "invalid_contact_input", true),
      "status_blocked_contact_count" => Map.get(artifact, "status_blocked_contact_count"),
      "row_derived_status_blocked_contact_count" =>
        Enum.count(rows, &contact_allocation_status_blocked_row?/1),
      "resource_blocked_contact_count" => Map.get(artifact, "resource_blocked_contact_count"),
      "row_derived_resource_blocked_contact_count" =>
        count_rows_with_key(rows, "source_resource_suppression"),
      "resource_blocking_dimension_counts" =>
        Map.get(artifact, "resource_blocking_dimension_counts"),
      "row_derived_resource_blocking_dimension_counts" =>
        count_rows_by_value(resource_blocked_rows, "resource_blocking_dimension"),
      "resource_blocked_contact_ids_by_blocking_dimension" =>
        Map.get(artifact, "resource_blocked_contact_ids_by_blocking_dimension"),
      "row_derived_resource_blocked_contact_ids_by_blocking_dimension" =>
        resource_blocked_rows
        |> group_row_ids_by_value("resource_blocking_dimension", "contact_id")
        |> sort_grouped_values(),
      "resource_blocked_contact_ids_by_spacecraft_id" =>
        Map.get(artifact, "resource_blocked_contact_ids_by_spacecraft_id"),
      "row_derived_resource_blocked_contact_ids_by_spacecraft_id" =>
        resource_blocked_rows
        |> group_row_ids_by_value("spacecraft_id", "contact_id")
        |> sort_grouped_values(),
      "review_row_count" => Enum.count(rows, &contact_allocation_review_row?/1),
      "allocation_status_counts" => Map.get(artifact, "allocation_status_counts"),
      "row_derived_allocation_status_counts" => count_rows_by_value(rows, "allocation_status"),
      "effective_allocation_status_counts" =>
        Map.get(artifact, "effective_allocation_status_counts"),
      "row_derived_effective_allocation_status_counts" =>
        count_rows_by_value(rows, "effective_allocation_status"),
      "allocation_reason_counts" => Map.get(artifact, "allocation_reason_counts"),
      "row_derived_allocation_reason_counts" => count_rows_by_value(rows, "allocation_reason"),
      "capacity_pack_status_counts" => count_rows_by_value(rows, "capacity_pack_status"),
      "reported_reduced_capacity_pack_status_counts" =>
        Map.get(artifact, "reduced_capacity_pack_status_counts"),
      "reported_capacity_pack_status_counts" => Map.get(artifact, "capacity_pack_status_counts"),
      "contact_ids_by_capacity_pack_status" =>
        rows
        |> group_row_ids_by_value("capacity_pack_status", "contact_id")
        |> sort_grouped_values(),
      "reported_capacity_pack_contact_ids_by_status" =>
        Map.get(artifact, "capacity_pack_contact_ids_by_status"),
      "reported_station_pressure_contact_ids_by_ground_station_id" =>
        Map.get(artifact, "station_pressure_contact_ids_by_ground_station_id"),
      "reported_station_pressure_contact_ids_by_availability" =>
        Map.get(artifact, "station_pressure_contact_ids_by_availability"),
      "reported_station_pressure_contact_ids_by_precedence_availability" =>
        Map.get(artifact, "station_pressure_contact_ids_by_precedence_availability"),
      "reported_station_pressure_contact_ids_by_precedence_rank" =>
        Map.get(artifact, "station_pressure_contact_ids_by_precedence_rank"),
      "contact_ids_by_effective_allocation_status" =>
        rows
        |> group_row_ids_by_value("effective_allocation_status", "contact_id")
        |> sort_grouped_values(),
      "row_derived_station_reservation_id_counts" =>
        row_value_counts(rows, "station_reservation_id"),
      "row_derived_station_reserved_by_counts" => row_value_counts(rows, "station_reserved_by"),
      "row_derived_station_reservation_status_counts" =>
        row_value_counts(rows, "station_reservation_status"),
      "contact_ids_by_station_reservation_match_status" =>
        rows
        |> group_row_ids_by_value("station_reservation_match_status", "contact_id")
        |> sort_grouped_values(),
      "station_reservation_match_status_counts" =>
        Map.get(artifact, "station_reservation_match_status_counts"),
      "station_calendar_trust_boundary_status_counts" =>
        Map.get(artifact, "station_calendar_trust_boundary_status_counts"),
      "calendar_entry_trust_boundary_status_counts" =>
        Map.get(artifact, "calendar_entry_trust_boundary_status_counts"),
      "reduced_capacity_pack_group_count" =>
        Map.get(artifact, "reduced_capacity_pack_group_count"),
      "reduced_capacity_pack_capacity_fraction_total" =>
        sum_numeric(reduced_capacity_pack_groups, "capacity_fraction"),
      "reduced_capacity_pack_used_fraction_total" =>
        sum_numeric(reduced_capacity_pack_groups, "used_capacity_fraction"),
      "reduced_capacity_pack_unused_fraction_total" =>
        sum_numeric(reduced_capacity_pack_groups, "unused_capacity_fraction"),
      "reduced_capacity_pack_selected_contact_count" =>
        sum_list_counts(reduced_capacity_pack_groups, "selected_contact_ids"),
      "reduced_capacity_pack_capacity_packed_contact_count" =>
        sum_list_counts(reduced_capacity_pack_groups, "capacity_packed_contact_ids"),
      "reduced_capacity_pack_deferred_contact_count" =>
        sum_list_counts(reduced_capacity_pack_groups, "deferred_contact_ids"),
      "required_capacity_fraction_total" => sum_numeric(rows, "required_capacity_fraction"),
      "selected_contact_count" => Enum.count(rows, &(Map.get(&1, "selected") == true)),
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

  defp contact_allocation_review_row?(row) do
    row["review_status"] == "operator_review_required" or
      row["allocation_status"] in ["blocked", "deferred"] or
      row["effective_allocation_status"] == "policy_blocked"
  end

  defp contact_allocation_status_blocked_row?(row) do
    reason = row["allocation_reason"]

    is_binary(reason) and
      (String.starts_with?(reason, "activity_status_") or
         String.starts_with?(reason, "approval_status_"))
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

  defp count_rows_by_value(rows, key) do
    rows
    |> Enum.map(&(Map.get(&1, key) || "unknown"))
    |> Enum.frequencies()
    |> Map.new(fn {value, count} -> {to_string(value), count} end)
  end

  defp count_rows_matching(rows, key, value) do
    Enum.count(rows, &(Map.get(&1, key) == value))
  end

  defp count_rows_with_key(rows, key) do
    Enum.count(rows, &Map.has_key?(&1, key))
  end

  defp sum_numeric(rows, key) do
    rows
    |> Enum.map(&Map.get(&1, key))
    |> Enum.filter(&is_number/1)
    |> Enum.sum()
  end

  defp sum_list_counts(rows, key) do
    rows
    |> Enum.map(&count(&1, key))
    |> Enum.sum()
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
