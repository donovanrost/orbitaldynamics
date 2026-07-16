defmodule OrbitalDynamics.Validation.ArtifactObservations.ContactAllocationStationPressureSummary do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)
    rows = map_rows(artifact, "rows")
    pressure_rows = station_pressure_rows(rows)
    review_rows = Enum.filter(pressure_rows, &(Map.get(&1, "review_status") != nil))

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "model" => Map.get(artifact, "model"),
      "source_artifact_type" => Map.get(artifact, "source_artifact_type"),
      "source" => Map.get(artifact, "source"),
      "input_contact_count" => Map.get(artifact, "input_contact_count"),
      "row_derived_input_contact_count" => length(rows),
      "station_pressure_contact_count" => Map.get(artifact, "station_pressure_contact_count"),
      "row_derived_station_pressure_contact_count" => length(pressure_rows),
      "station_pressure_review_contact_count" =>
        Map.get(artifact, "station_pressure_review_contact_count"),
      "row_derived_station_pressure_review_contact_count" => length(review_rows),
      "station_pressure_contact_ids" => Map.get(artifact, "station_pressure_contact_ids"),
      "station_pressure_contact_keys" =>
        artifact
        |> list_values("station_pressure_contact_ids")
        |> Enum.join("|"),
      "row_derived_station_pressure_contact_ids" =>
        unique_row_values(pressure_rows, "contact_id"),
      "row_derived_station_pressure_contact_keys" =>
        pressure_rows
        |> unique_row_values("contact_id")
        |> Enum.join("|"),
      "station_pressure_review_contact_ids" =>
        Map.get(artifact, "station_pressure_review_contact_ids"),
      "station_pressure_review_contact_keys" =>
        artifact
        |> list_values("station_pressure_review_contact_ids")
        |> Enum.join("|"),
      "row_derived_station_pressure_review_contact_ids" =>
        unique_row_values(review_rows, "contact_id"),
      "row_derived_station_pressure_review_contact_keys" =>
        review_rows
        |> unique_row_values("contact_id")
        |> Enum.join("|"),
      "station_pressure_contact_ids_by_ground_station_id" =>
        Map.get(artifact, "station_pressure_contact_ids_by_ground_station_id"),
      "row_derived_station_pressure_contact_ids_by_ground_station_id" =>
        pressure_rows
        |> group_row_ids_by_value("ground_station_id", "contact_id")
        |> sort_grouped_values(),
      "station_pressure_contact_ids_by_availability" =>
        Map.get(artifact, "station_pressure_contact_ids_by_availability"),
      "row_derived_station_pressure_contact_ids_by_availability" =>
        pressure_rows
        |> group_row_ids_by_value("station_availability", "contact_id")
        |> sort_grouped_values(),
      "station_pressure_contact_ids_by_status" =>
        Map.get(artifact, "station_pressure_contact_ids_by_status"),
      "row_derived_station_pressure_contact_ids_by_status" =>
        pressure_rows
        |> group_row_ids_by_value("station_calendar_status", "contact_id")
        |> sort_grouped_values(),
      "station_pressure_contact_counts_by_status" =>
        Map.get(artifact, "station_pressure_contact_counts_by_status"),
      "row_derived_station_pressure_contact_counts_by_status" =>
        row_value_counts(pressure_rows, "station_calendar_status"),
      "station_pressure_contact_ids_by_precedence_availability" =>
        Map.get(artifact, "station_pressure_contact_ids_by_precedence_availability"),
      "row_derived_station_pressure_contact_ids_by_precedence_availability" =>
        pressure_rows
        |> group_row_ids_by_value("station_calendar_precedence_availability", "contact_id")
        |> sort_grouped_values(),
      "station_pressure_contact_ids_by_precedence_rank" =>
        Map.get(artifact, "station_pressure_contact_ids_by_precedence_rank"),
      "row_derived_station_pressure_contact_ids_by_precedence_rank" =>
        pressure_rows
        |> group_row_ids_by_value("station_calendar_precedence_rank", "contact_id")
        |> sort_grouped_values(),
      "station_pressure_contact_ids_by_direction_and_ground_station_id" =>
        Map.get(artifact, "station_pressure_contact_ids_by_direction_and_ground_station_id"),
      "row_derived_station_pressure_contact_ids_by_direction_and_ground_station_id" =>
        contact_ids_by_direction_and_ground_station_id(pressure_rows),
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
