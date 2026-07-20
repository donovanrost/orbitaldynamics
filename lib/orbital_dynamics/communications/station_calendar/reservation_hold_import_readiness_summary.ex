defmodule OrbitalDynamics.Communications.StationCalendar.ReservationHoldImportReadinessSummary do
  @moduledoc false

  @reservation_schema_contract "station_reservation_report.v1"
  @schema_contract "station_reservation_hold_import_readiness_summary.v1"

  alias OrbitalDynamics.Communications.StationCalendar.ReservationSummaryValues
  alias OrbitalDynamics.Communications.StationCalendar.StationMatching

  def build(summary, model_limits) do
    summary = stringify_keys(summary)

    rows =
      summary
      |> Map.get("review_rows", [])
      |> Enum.filter(&is_map/1)
      |> Enum.map(&put_reservation_hold_import_status/1)

    %{
      "schema_contract" => @schema_contract,
      "model" => "artifact_only_station_reservation_hold_import_readiness_summary",
      "source_artifact_type" =>
        Map.get(summary, "source_artifact_type", @reservation_schema_contract),
      "source" => summary["source"],
      "model_limits" => model_limits,
      "reservation_hold_count" => length(rows),
      "import_readiness_status" => if(rows == [], do: "clear", else: "review_required"),
      "import_classification" => if(rows == [], do: "not_applicable", else: "review_only"),
      "ready_for_import_count" => 0,
      "review_required_before_import_count" => length(rows),
      "no_import_required_count" => 0,
      "reservation_hold_import_status_counts" =>
        count_by(rows, "station_reservation_hold_import_status"),
      "reservation_hold_status_counts" => reservation_status_counts_for_rows(rows),
      "reservation_hold_expiration_status_counts" =>
        count_by(rows, "station_reservation_expiration_status"),
      "required_import_action_counts" => count_by(rows, "required_operator_action"),
      "reservation_hold_ids" => ReservationSummaryValues.row_ids(rows),
      "reservation_hold_ids_by_import_status" =>
        ReservationSummaryValues.ids_by(rows, "station_reservation_hold_import_status"),
      "reservation_hold_ids_by_expiration_status" =>
        ReservationSummaryValues.ids_by(rows, "station_reservation_expiration_status"),
      "reservation_hold_ids_by_status" =>
        ReservationSummaryValues.ids_by_row_values(rows, "reservation_statuses"),
      "reservation_hold_ids_by_reserved_by" =>
        ReservationSummaryValues.ids_by_row_values(rows, "reserved_by"),
      "reservation_hold_ids_by_required_import_action" =>
        ReservationSummaryValues.ids_by(rows, "required_operator_action"),
      "reservation_hold_ids_by_direction" => reservation_ids_by_direction(rows),
      "reservation_hold_ids_by_direction_and_ground_station_id" =>
        reservation_ids_by_direction_and_ground_station(rows),
      "reservation_hold_contact_ids_by_import_status" =>
        reservation_contact_ids_by(rows, "station_reservation_hold_import_status"),
      "reservation_hold_contact_ids_by_expiration_status" =>
        reservation_contact_ids_by(rows, "station_reservation_expiration_status"),
      "reservation_hold_contact_ids_by_direction" => reservation_contact_ids_by_direction(rows),
      "reservation_hold_contact_ids_by_direction_and_ground_station_id" =>
        reservation_contact_ids_by_direction_and_ground_station(rows),
      "review_contact_ids" => reservation_contact_ids(rows),
      "import_readiness_rows" => rows,
      "assumptions" =>
        %{
          "execution_boundary" => "artifact_only_no_provider_or_cadence_writes",
          "source" => "station_reservation_report.v1",
          "operator_authority" => "not_granted_by_import_readiness_summary",
          "provider_write" => "not_performed_by_summary",
          "cadence_write" => "not_performed_by_summary",
          "reservation_acceptance" => "not_performed_by_summary",
          "deadline_evaluation" =>
            get_in(summary, ["assumptions", "deadline_evaluation"]) || "not_evaluated"
        }
        |> maybe_put("now_s", get_in(summary, ["assumptions", "now_s"]))
    }
    |> compact_map()
  end

  defp put_reservation_hold_import_status(row) do
    row
    |> Map.put("station_reservation_hold_import_status", "review_required_before_import")
    |> Map.put_new("required_operator_action", "review_station_reservation_hold")
  end

  defp reservation_ids_by_direction(rows) do
    rows
    |> Enum.flat_map(fn row ->
      ReservationSummaryValues.id_value_pairs(
        Map.get(row, "reservation_ids"),
        row_directions(row)
      )
    end)
    |> ReservationSummaryValues.id_pairs_to_map()
  end

  defp reservation_ids_by_direction_and_ground_station(rows) do
    rows
    |> Enum.reduce(%{}, fn row, acc ->
      put_nested_stable_ids(
        acc,
        row_directions(row),
        Map.get(row, "ground_station_id"),
        Map.get(row, "reservation_ids")
      )
    end)
  end

  defp reservation_status_counts_for_rows(rows) do
    rows
    |> Enum.flat_map(&Map.get(&1, "reservation_statuses", []))
    |> Enum.frequencies()
  end

  defp reservation_contact_ids_by(rows, field) do
    rows
    |> Enum.group_by(&Map.get(&1, field), &Map.get(&1, "contact_id"))
    |> sorted_id_map()
  end

  defp reservation_contact_ids_by_direction(rows) do
    rows
    |> Enum.flat_map(fn row ->
      ReservationSummaryValues.id_value_pairs(
        List.wrap(Map.get(row, "contact_id")),
        row_directions(row)
      )
    end)
    |> ReservationSummaryValues.id_pairs_to_map()
  end

  defp reservation_contact_ids_by_direction_and_ground_station(rows) do
    rows
    |> Enum.reduce(%{}, fn row, acc ->
      put_nested_stable_ids(
        acc,
        row_directions(row),
        Map.get(row, "ground_station_id"),
        List.wrap(Map.get(row, "contact_id"))
      )
    end)
  end

  defp reservation_contact_ids(rows) do
    rows
    |> Enum.map(& &1["contact_id"])
    |> sorted_values()
  end

  defp row_directions(row) do
    [
      Map.get(row, "direction"),
      Map.get(row, "directions"),
      Map.get(row, "station_calendar_directions")
    ]
    |> List.flatten()
    |> Enum.map(&normalize_direction/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp put_nested_stable_ids(acc, directions, ground_station_id, ids) do
    ids = ids |> List.wrap() |> Enum.reject(&is_nil/1)

    if directions == [] or ground_station_id in [nil, ""] or ids == [] do
      acc
    else
      Enum.reduce(directions, acc, fn direction, direction_acc ->
        Map.update(direction_acc, direction, %{ground_station_id => sorted_values(ids)}, fn
          station_map ->
            Map.update(station_map, ground_station_id, sorted_values(ids), fn existing_ids ->
              sorted_values(existing_ids ++ ids)
            end)
        end)
      end)
    end
  end

  defp count_by(rows, field) do
    rows
    |> Enum.map(&Map.get(&1, field))
    |> Enum.reject(&is_nil/1)
    |> Enum.frequencies()
  end

  defp sorted_id_map(groups) do
    groups
    |> Enum.reject(fn {key, ids} -> is_nil(key) or Enum.all?(ids, &is_nil/1) end)
    |> Map.new(fn {key, ids} -> {key, sorted_values(ids)} end)
  end

  defp sorted_values(values) do
    values
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp normalize_direction(direction), do: StationMatching.normalize_direction(direction)

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_key(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value) when is_boolean(value), do: value
  defp stringify_keys(nil), do: nil
  defp stringify_keys(value) when is_atom(value), do: Atom.to_string(value)
  defp stringify_keys(value), do: value

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, _key, ""), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp encode_key(key) when is_atom(key), do: Atom.to_string(key)
  defp encode_key(key), do: key
end
