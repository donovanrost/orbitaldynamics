defmodule OrbitalDynamics.Validation.ArtifactObservations.StationReservationHoldImportReadinessSummary do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)
    rows = map_rows(artifact, "import_readiness_rows")

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "model" => Map.get(artifact, "model"),
      "source_artifact_type" => Map.get(artifact, "source_artifact_type"),
      "source" => Map.get(artifact, "source"),
      "reservation_hold_count" => Map.get(artifact, "reservation_hold_count"),
      "import_readiness_status" => Map.get(artifact, "import_readiness_status"),
      "import_classification" => Map.get(artifact, "import_classification"),
      "ready_for_import_count" => Map.get(artifact, "ready_for_import_count"),
      "review_required_before_import_count" =>
        Map.get(artifact, "review_required_before_import_count"),
      "no_import_required_count" => Map.get(artifact, "no_import_required_count"),
      "reservation_hold_import_status_counts" =>
        Map.get(artifact, "reservation_hold_import_status_counts") || %{},
      "row_derived_reservation_hold_import_status_counts" =>
        count_rows_by_value(rows, "station_reservation_hold_import_status"),
      "required_import_action_counts" =>
        Map.get(artifact, "required_import_action_counts") || %{},
      "row_derived_required_import_action_counts" =>
        count_rows_by_value(rows, "required_operator_action"),
      "reservation_hold_ids_by_import_status" =>
        Map.get(artifact, "reservation_hold_ids_by_import_status") || %{},
      "row_derived_reservation_hold_ids_by_import_status" =>
        group_row_list_ids_by_value(
          rows,
          "station_reservation_hold_import_status",
          "reservation_ids"
        ),
      "reservation_hold_ids_by_required_import_action" =>
        Map.get(artifact, "reservation_hold_ids_by_required_import_action") || %{},
      "row_derived_reservation_hold_ids_by_required_import_action" =>
        group_row_list_ids_by_value(rows, "required_operator_action", "reservation_ids"),
      "reservation_hold_contact_ids_by_import_status" =>
        Map.get(artifact, "reservation_hold_contact_ids_by_import_status") || %{},
      "row_derived_reservation_hold_contact_ids_by_import_status" =>
        rows
        |> group_row_ids_by_present_value("station_reservation_hold_import_status", "contact_id")
        |> sort_grouped_values(),
      "execution_boundary" => get_in(artifact, ["assumptions", "execution_boundary"]),
      "provider_write" => get_in(artifact, ["assumptions", "provider_write"]),
      "cadence_write" => get_in(artifact, ["assumptions", "cadence_write"]),
      "reservation_acceptance" => get_in(artifact, ["assumptions", "reservation_acceptance"]),
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

  defp sort_grouped_values(grouped_values) do
    Map.new(grouped_values, fn {key, values} -> {key, Enum.sort(values)} end)
  end

  defp count_rows_by_value(rows, key) do
    rows
    |> Enum.map(&(Map.get(&1, key) || "unknown"))
    |> Enum.frequencies()
    |> Map.new(fn {value, count} -> {to_string(value), count} end)
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
