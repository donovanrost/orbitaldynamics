defmodule OrbitalDynamics.Communications.StationCalendar.PrecedenceSummary do
  @moduledoc false

  def build(report, opts) do
    report = stringify_keys(report)
    schema_contract = Keyword.fetch!(opts, :schema_contract)
    source_artifact_type = Keyword.fetch!(opts, :source_artifact_type)
    model_limits = Keyword.fetch!(opts, :model_limits)

    rows =
      report
      |> Map.get("affected_contacts", [])
      |> Enum.filter(&is_map/1)

    reserved_under_higher_precedence_rows =
      Enum.filter(rows, &reserved_under_higher_precedence?/1)

    %{
      "schema_contract" => schema_contract,
      "model" => "artifact_only_station_calendar_precedence_summary",
      "model_limits" => model_limits,
      "source_artifact_type" => Map.get(report, "schema_contract", source_artifact_type),
      "source" => get_in(report, ["assumptions", "source"]) || report["source"],
      "affected_contact_count" => length(rows),
      "precedence_review_status" => if(rows == [], do: "clear", else: "review_required"),
      "applied_availability_counts" => count_by(rows, "station_availability"),
      "applied_status_counts" => count_by(rows, "status"),
      "overlap_availability_counts" => overlap_availability_counts(rows),
      "affected_contact_ids_by_applied_availability" =>
        affected_contact_ids_by_field(rows, "station_availability"),
      "affected_contact_ids_by_applied_status" => affected_contact_ids_by_field(rows, "status"),
      "affected_contact_ids_by_overlap_availability" =>
        affected_contact_ids_by_overlap_availability(rows),
      "reserved_under_higher_precedence_contact_count" =>
        length(reserved_under_higher_precedence_rows),
      "reserved_under_higher_precedence_contact_ids" =>
        affected_contact_ids(reserved_under_higher_precedence_rows),
      "reserved_under_higher_precedence_contact_ids_by_applied_availability" =>
        affected_contact_ids_by_field(
          reserved_under_higher_precedence_rows,
          "station_availability"
        ),
      "reserved_under_higher_precedence_contact_ids_by_applied_status" =>
        affected_contact_ids_by_field(reserved_under_higher_precedence_rows, "status"),
      "reserved_under_higher_precedence_reservation_ids" =>
        row_list_values(
          reserved_under_higher_precedence_rows,
          "station_calendar_reservation_ids"
        ),
      "reserved_under_higher_precedence_reservation_ids_by_status" =>
        reservation_ids_by_row_list_field(
          reserved_under_higher_precedence_rows,
          "station_calendar_reservation_statuses"
        ),
      "reserved_under_higher_precedence_reservation_ids_by_reserved_by" =>
        reservation_ids_by_row_list_field(
          reserved_under_higher_precedence_rows,
          "station_calendar_reserved_by"
        ),
      "reserved_under_higher_precedence_contact_ids_by_reservation_status" =>
        contact_ids_by_row_list_field(
          reserved_under_higher_precedence_rows,
          "station_calendar_reservation_statuses"
        ),
      "reserved_under_higher_precedence_contact_ids_by_reserved_by" =>
        contact_ids_by_row_list_field(
          reserved_under_higher_precedence_rows,
          "station_calendar_reserved_by"
        ),
      "unavailable_contact_ids" =>
        affected_contact_ids_by_applied_availability(rows, ["unavailable", "maintenance"]),
      "reserved_overlap_contact_ids" => affected_contact_ids_by_overlap_value(rows, "reserved"),
      "reduced_capacity_contact_ids" =>
        affected_contact_ids_by_overlap_value(rows, "reduced_capacity"),
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_provider_reservation",
        "scope" => "station_calendar_availability_precedence_review",
        "operator_authority" => "not_granted_by_summary"
      }
    }
    |> compact_map()
  end

  defp affected_contact_ids_by_field(affected, field) do
    affected
    |> Enum.group_by(&Map.get(&1, field), &Map.get(&1, "contact_id"))
    |> sorted_id_map()
  end

  defp affected_contact_ids(rows) do
    rows
    |> Enum.map(& &1["contact_id"])
    |> sorted_values()
  end

  defp affected_contact_ids_by_applied_availability(rows, availability_values) do
    rows
    |> Enum.filter(&(&1["station_availability"] in availability_values))
    |> affected_contact_ids()
  end

  defp affected_contact_ids_by_overlap_value(rows, availability) do
    rows
    |> Enum.filter(&(availability in List.wrap(&1["station_calendar_overlap_availabilities"])))
    |> affected_contact_ids()
  end

  defp affected_contact_ids_by_overlap_availability(rows) do
    rows
    |> Enum.flat_map(fn row ->
      row
      |> Map.get("station_calendar_overlap_availabilities", [])
      |> List.wrap()
      |> Enum.map(&{&1, row["contact_id"]})
    end)
    |> Enum.reject(fn {availability, contact_id} ->
      is_nil(availability) or is_nil(contact_id)
    end)
    |> Enum.group_by(fn {availability, _contact_id} -> availability end, fn {_availability,
                                                                             contact_id} ->
      contact_id
    end)
    |> Map.new(fn {availability, contact_ids} -> {availability, sorted_values(contact_ids)} end)
  end

  defp row_list_values(rows, field) do
    rows
    |> Enum.flat_map(&List.wrap(&1[field]))
    |> sorted_values()
  end

  defp contact_ids_by_row_list_field(rows, field) do
    rows
    |> Enum.flat_map(fn row ->
      row
      |> Map.get(field, [])
      |> List.wrap()
      |> Enum.map(&{&1, row["contact_id"]})
    end)
    |> Enum.reject(fn {group, contact_id} -> is_nil(group) or is_nil(contact_id) end)
    |> Enum.group_by(fn {group, _contact_id} -> encode_value(group) end, fn {_group, contact_id} ->
      contact_id
    end)
    |> sorted_id_map()
  end

  defp reservation_ids_by_row_list_field(rows, field) do
    rows
    |> Enum.flat_map(fn row ->
      reservation_ids = List.wrap(row["station_calendar_reservation_ids"])
      group_values = List.wrap(row[field])

      Enum.zip(group_values, reservation_ids)
    end)
    |> Enum.reject(fn {group, reservation_id} -> is_nil(group) or is_nil(reservation_id) end)
    |> Enum.group_by(fn {group, _reservation_id} -> encode_value(group) end, fn {_group,
                                                                                 reservation_id} ->
      reservation_id
    end)
    |> sorted_id_map()
  end

  defp overlap_availability_counts(rows) do
    rows
    |> Enum.flat_map(&List.wrap(&1["station_calendar_overlap_availabilities"]))
    |> Enum.reject(&is_nil/1)
    |> Enum.frequencies()
  end

  defp reserved_under_higher_precedence?(row) do
    "reserved" in List.wrap(row["station_calendar_overlap_availabilities"]) and
      row["station_availability"] in ["unavailable", "maintenance"]
  end

  defp sorted_id_map(groups) do
    groups
    |> Enum.reject(fn {key, ids} -> is_nil(key) or Enum.all?(ids, &is_nil/1) end)
    |> Map.new(fn {key, ids} -> {key, sorted_values(ids)} end)
  end

  defp count_by(rows, field) do
    rows
    |> Enum.map(&Map.get(&1, field))
    |> Enum.reject(&is_nil/1)
    |> Enum.frequencies()
  end

  defp sorted_values(values) do
    values
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

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

  defp encode_key(key) when is_atom(key), do: Atom.to_string(key)
  defp encode_key(key), do: key

  defp encode_value(value) when is_float(value),
    do: :erlang.float_to_binary(value, decimals: 6)

  defp encode_value(value), do: to_string(value)
end
