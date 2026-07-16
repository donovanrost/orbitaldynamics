defmodule OrbitalDynamics.Validation.ArtifactObservations.CadenceImportManifest do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)
    rows = map_rows(artifact, "rows")

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "schema_version" => Map.get(artifact, "schema_version"),
      "model" => Map.get(artifact, "model"),
      "manifest_id" => Map.get(artifact, "manifest_id"),
      "source_artifact_type" => Map.get(artifact, "source_artifact_type"),
      "source_artifact_id" => Map.get(artifact, "source_artifact_id"),
      "row_count" => length(rows),
      "ready_count" => Map.get(artifact, "ready_count"),
      "row_derived_ready_count" => count_rows_matching(rows, "import_status", "ready_for_import"),
      "blocked_count" => Map.get(artifact, "blocked_count"),
      "row_derived_blocked_count" =>
        count_rows_matching(rows, "import_status", "blocked_missing_cadence_import"),
      "review_required_count" => Map.get(artifact, "review_required_count"),
      "missing_import_count" => Map.get(artifact, "missing_import_count"),
      "row_derived_missing_import_count" =>
        count_rows_matching(rows, "cadence_import_status", "missing"),
      "source_review_count" => get_in(artifact, ["provenance", "source_review_count"]),
      "import_status_counts" => Map.get(artifact, "import_status_counts"),
      "row_derived_import_status_counts" => count_rows_by_value(rows, "import_status"),
      "import_action_counts" => Map.get(artifact, "import_action_counts"),
      "row_derived_import_action_counts" => count_rows_by_value(rows, "import_action"),
      "cadence_import_status_counts" => Map.get(artifact, "cadence_import_status_counts"),
      "row_derived_cadence_import_status_counts" =>
        count_rows_by_value(rows, "cadence_import_status"),
      "required_operator_action_counts" => count_rows_by_value(rows, "required_operator_action"),
      "row_derived_required_operator_action_counts" =>
        count_rows_by_value(rows, "required_operator_action"),
      "source_review_type_counts" => count_rows_by_value(rows, "source_review_type"),
      "row_derived_source_review_type_counts" => count_rows_by_value(rows, "source_review_type"),
      "import_side_counts" => count_rows_by_value(rows, "import_side"),
      "row_derived_import_side_counts" => count_rows_by_value(rows, "import_side"),
      "source_review_queue_counts" => Map.get(artifact, "source_review_queue_counts"),
      "row_derived_source_review_queue_counts" =>
        count_rows_by_value(rows, "source_review_queue_key"),
      "manifest_row_ids_by_import_status" =>
        rows
        |> group_row_ids_by_value("import_status", "id")
        |> sort_grouped_values(),
      "row_derived_manifest_row_ids_by_import_status" =>
        rows
        |> group_row_ids_by_value("import_status", "id")
        |> sort_grouped_values(),
      "resource_availability_import_row_count" =>
        rows
        |> Enum.count(fn row ->
          value = Map.get(row, "resource_availability_pressure_count")
          is_number(value) and value > 0
        end),
      "row_derived_resource_availability_pressure_count" =>
        sum_rows_numeric(rows, "resource_availability_pressure_count"),
      "row_derived_resource_availability_reason_counts" =>
        merge_row_count_maps(rows, "resource_availability_reason_counts"),
      "row_derived_resource_availability_reason_keys" =>
        rows
        |> Enum.flat_map(&list_values(&1, "resource_availability_reason_ids"))
        |> Enum.uniq()
        |> Enum.sort()
        |> Enum.join("|"),
      "row_derived_unavailable_resource_reason_keys" =>
        rows
        |> Enum.flat_map(&list_values(&1, "unavailable_resource_reason_ids"))
        |> Enum.uniq()
        |> Enum.sort()
        |> Enum.join("|"),
      "resource_projection_battery_handoff_count" =>
        resource_projection_battery_handoff_count(rows),
      "source_review_battery_handoff_count" => source_review_battery_handoff_count(rows),
      "total_resource_projection_battery_energy_consumed_wh" =>
        sum_numeric(rows, "total_battery_energy_consumed_wh"),
      "total_resource_projection_battery_energy_generated_wh" =>
        sum_numeric(rows, "total_battery_energy_generated_wh"),
      "net_resource_projection_battery_energy_delta_wh" =>
        sum_numeric(rows, "net_battery_energy_delta_wh"),
      "peak_resource_projection_battery_overuse_wh" =>
        max_numeric(rows, "peak_battery_overuse_wh"),
      "execution_boundary" => get_in(artifact, ["assumptions", "execution_boundary"]),
      "authorization_boundary" => get_in(artifact, ["assumptions", "authorization_boundary"]),
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

  defp sum_rows_numeric(rows, key) do
    rows
    |> Enum.map(&numeric_count(&1, key))
    |> Enum.sum()
  end

  defp numeric_count(report, field) when is_map(report) do
    case Map.get(report, field) do
      value when is_integer(value) and value >= 0 -> value
      value when is_float(value) and value >= 0 -> trunc(value)
      _value -> 0
    end
  end

  defp numeric_count(_report, _field), do: 0

  defp merge_row_count_maps(rows, key) do
    rows
    |> Enum.map(&Map.get(&1, key))
    |> Enum.filter(&is_map/1)
    |> Enum.reduce(%{}, fn count_map, acc ->
      Enum.reduce(count_map, acc, fn
        {count_key, count_value}, acc when is_integer(count_value) and count_value >= 0 ->
          Map.update(acc, to_string(count_key), count_value, &(&1 + count_value))

        {_count_key, _count_value}, acc ->
          acc
      end)
    end)
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

  defp max_numeric(rows, key) do
    rows
    |> Enum.map(&Map.get(&1, key))
    |> Enum.filter(&is_number/1)
    |> case do
      [] -> 0.0
      values -> Enum.max(values)
    end
  end

  defp resource_projection_battery_handoff_count(rows) do
    Enum.count(rows, fn row ->
      Map.get(row, "source_review_type") == "resource_projection_review" or
        Map.get(row, "review_type") == "resource_projection_review"
    end)
    |> min(count_rows_with_key(rows, "total_battery_energy_consumed_wh"))
  end

  defp source_review_battery_handoff_count(rows) do
    Enum.count(rows, fn row ->
      source_review_row = Map.get(row, "source_review_row")

      is_map(source_review_row) and
        Map.get(source_review_row, "review_type") == "resource_projection_review" and
        is_number(Map.get(source_review_row, "total_battery_energy_consumed_wh"))
    end)
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
