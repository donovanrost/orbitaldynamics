defmodule OrbitalDynamics.Validation.ArtifactObservations.ContactAllocationSummary do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)
    rows = map_rows(artifact, "rows")
    review_rows = map_rows(artifact, "review_rows")
    station_pressure_rows = station_pressure_rows(rows)

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "model" => Map.get(artifact, "model"),
      "source_artifact_type" => Map.get(artifact, "source_artifact_type"),
      "source" => Map.get(artifact, "source"),
      "input_contact_count" => Map.get(artifact, "input_contact_count"),
      "row_derived_input_contact_count" => length(rows),
      "allocated_contact_count" => Map.get(artifact, "allocated_contact_count"),
      "row_derived_allocated_contact_count" =>
        Enum.count(rows, &(Map.get(&1, "allocation_status") == "allocated")),
      "deferred_contact_count" => Map.get(artifact, "deferred_contact_count"),
      "row_derived_deferred_contact_count" =>
        Enum.count(rows, &(Map.get(&1, "allocation_status") == "deferred")),
      "blocked_contact_count" => Map.get(artifact, "blocked_contact_count"),
      "row_derived_blocked_contact_count" =>
        Enum.count(rows, &(Map.get(&1, "allocation_status") == "blocked")),
      "review_row_count" => Map.get(artifact, "review_row_count"),
      "row_derived_review_row_count" => length(review_rows),
      "allocation_status_counts" => Map.get(artifact, "allocation_status_counts"),
      "row_derived_allocation_status_counts" => row_value_counts(rows, "allocation_status"),
      "effective_allocation_status_counts" =>
        Map.get(artifact, "effective_allocation_status_counts"),
      "row_derived_effective_allocation_status_counts" =>
        row_value_counts(rows, "effective_allocation_status"),
      "allocation_reason_counts" => Map.get(artifact, "allocation_reason_counts"),
      "row_derived_allocation_reason_counts" => row_value_counts(rows, "allocation_reason"),
      "contact_ids_by_effective_allocation_status" =>
        Map.get(artifact, "contact_ids_by_effective_allocation_status"),
      "row_derived_contact_ids_by_effective_allocation_status" =>
        rows
        |> group_row_ids_by_value("effective_allocation_status", "contact_id")
        |> sort_grouped_values(),
      "station_pressure_contact_ids_by_ground_station_id" =>
        Map.get(artifact, "station_pressure_contact_ids_by_ground_station_id"),
      "row_derived_station_pressure_contact_ids_by_ground_station_id" =>
        station_pressure_rows
        |> group_row_ids_by_value("ground_station_id", "contact_id")
        |> sort_grouped_values(),
      "station_pressure_contact_ids_by_availability" =>
        Map.get(artifact, "station_pressure_contact_ids_by_availability"),
      "row_derived_station_pressure_contact_ids_by_availability" =>
        station_pressure_rows
        |> group_row_ids_by_value("station_availability", "contact_id")
        |> sort_grouped_values(),
      "station_pressure_contact_ids_by_status" =>
        Map.get(artifact, "station_pressure_contact_ids_by_status"),
      "row_derived_station_pressure_contact_ids_by_status" =>
        station_pressure_rows
        |> group_row_ids_by_value("station_calendar_status", "contact_id")
        |> sort_grouped_values(),
      "station_pressure_contact_counts_by_status" =>
        Map.get(artifact, "station_pressure_contact_counts_by_status"),
      "row_derived_station_pressure_contact_counts_by_status" =>
        row_value_counts(station_pressure_rows, "station_calendar_status"),
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

  defp station_pressure_rows(rows) do
    Enum.filter(rows, fn row ->
      Map.get(row, "station_availability") != nil or
        Map.get(row, "station_calendar_precedence_availability") != nil or
        Map.get(row, "station_calendar_precedence_rank") != nil
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
