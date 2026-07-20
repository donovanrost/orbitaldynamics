defmodule OrbitalDynamics.Communications.LinkCapacity.Summary do
  @moduledoc false

  @schema_contract "link_capacity_report.v1"
  @summary_schema_contract "link_capacity_summary.v1"

  alias OrbitalDynamics.Communications.LinkCapacity.ContactIdentity
  alias OrbitalDynamics.Communications.LinkCapacity.ContactNormalization
  alias OrbitalDynamics.Communications.LinkCapacity.StationAvailability
  alias OrbitalDynamics.Communications.LinkCapacity.StationReservationEvidence

  def build(report, context) do
    report = stringify_keys(report)

    rows =
      report
      |> Map.get("rows", [])
      |> Enum.filter(&is_map/1)
      |> Enum.map(&normalize_station_calendar_status_fields(&1, context))

    %{
      "schema_contract" => @summary_schema_contract,
      "model" => "artifact_only_link_capacity_summary",
      "source_artifact_type" => Map.get(report, "schema_contract", @schema_contract),
      "source" => report["source"],
      "model_limits" => context.model_limits,
      "station_count" => length(row_ground_station_ids(rows)),
      "contact_count" => row_scalar_count_sum(rows, "contact_count"),
      "effective_contact_count" => row_scalar_count_sum(rows, "effective_contact_count"),
      "ignored_contact_count" => row_scalar_count_sum(rows, "ignored_contact_count"),
      "selected_contact_count" => row_scalar_count_sum(rows, "selected_contact_count"),
      "ignored_selected_contact_count" =>
        row_scalar_count_sum(rows, "ignored_selected_contact_count"),
      "required_downlink_contact_count" => row_list_count(rows, "required_downlink_contact_ids"),
      "actual_throughput_contact_count" => row_list_count(rows, "actual_throughput_contact_ids"),
      "actual_completion_contact_count" => row_list_count(rows, "actual_completion_contact_ids"),
      "unmatched_actual_throughput_contact_count" =>
        row_list_count(rows, "unmatched_actual_throughput_contact_ids"),
      "ambiguous_actual_throughput_contact_count" =>
        row_list_count(rows, "ambiguous_actual_throughput_contact_ids"),
      "unmatched_actual_completion_contact_count" =>
        row_list_count(rows, "unmatched_actual_completion_contact_ids"),
      "ambiguous_actual_completion_contact_count" =>
        row_list_count(rows, "ambiguous_actual_completion_contact_ids"),
      "invalid_contact_input_count" =>
        report_list_count(report, "invalid_contact_inputs", "invalid_contact_input_ids"),
      "invalid_selected_contact_input_count" =>
        report_list_count(
          report,
          "invalid_selected_contact_inputs",
          "invalid_selected_contact_input_ids"
        ),
      "invalid_policy_required_downlink_station_count" =>
        length(report_string_values(report, "invalid_policy_required_downlink_station_ids")),
      "downlink_requirement_status" => report["downlink_requirement_status"],
      "actual_downlink_requirement_status" => report["actual_downlink_requirement_status"],
      "selection_utilization_status" => report["selection_utilization_status"],
      "selected_downlink_shortfall_mb" => row_numeric_sum(rows, "selected_downlink_shortfall_mb"),
      "actual_downlink_shortfall_mb" => row_numeric_sum(rows, "actual_downlink_shortfall_mb"),
      "capacity_adjusted_throughput_mb" =>
        row_numeric_sum(rows, "capacity_adjusted_throughput_mb"),
      "selected_capacity_adjusted_throughput_mb" =>
        row_numeric_sum(rows, "selected_capacity_adjusted_throughput_mb"),
      "unused_capacity_adjusted_throughput_mb" =>
        row_numeric_sum(rows, "unused_capacity_adjusted_throughput_mb"),
      "ignored_contact_reason_counts" =>
        row_count_map(rows, "ignored_contact_reason_counts") || %{},
      "ignored_selected_contact_reason_counts" =>
        row_count_map(rows, "ignored_selected_contact_reason_counts") || %{},
      "station_reservation_match_status_counts" =>
        row_station_reservation_match_status_counts(rows) || %{},
      "station_calendar_entry_ids" => row_station_calendar_entry_ids(rows),
      "station_calendar_provider_ids" => row_station_calendar_provider_ids(rows),
      "station_calendar_provider_entry_ids" => row_station_calendar_provider_entry_ids(rows),
      "station_reservation_ids" => row_station_reservation_ids(rows) || [],
      "station_reservation_expires_at_s" => row_station_reservation_expires_at_s(rows) || [],
      "station_reserved_bys" => row_station_reserved_bys(rows) || [],
      "station_reservation_statuses" => row_station_reservation_statuses(rows) || [],
      "contact_ids" => row_list_values(rows, "contact_ids", :stable_id),
      "selected_contact_ids" => row_list_values(rows, "selected_contact_ids", :stable_id),
      "ignored_contact_ids" => row_list_values(rows, "ignored_contact_ids", :stable_id) || [],
      "ignored_selected_contact_ids" =>
        row_list_values(rows, "ignored_selected_contact_ids", :stable_id) || [],
      "required_downlink_contact_ids" =>
        row_list_values(rows, "required_downlink_contact_ids", :stable_id) || [],
      "actual_throughput_contact_ids" =>
        row_list_values(rows, "actual_throughput_contact_ids", :stable_id) || [],
      "actual_completion_contact_ids" =>
        row_list_values(rows, "actual_completion_contact_ids", :stable_id) || [],
      "unmatched_actual_throughput_contact_ids" =>
        row_list_values(rows, "unmatched_actual_throughput_contact_ids", :stable_id) || [],
      "ambiguous_actual_throughput_contact_ids" =>
        row_list_values(rows, "ambiguous_actual_throughput_contact_ids", :stable_id) || [],
      "unmatched_actual_completion_contact_ids" =>
        row_list_values(rows, "unmatched_actual_completion_contact_ids", :stable_id) || [],
      "ambiguous_actual_completion_contact_ids" =>
        row_list_values(rows, "ambiguous_actual_completion_contact_ids", :stable_id) || [],
      "ambiguous_selected_contact_ids" =>
        row_list_values(rows, "ambiguous_selected_contact_ids", :stable_id) || [],
      "unmatched_selected_contact_ids" =>
        report |> Map.get("unmatched_selected_contact_ids", []) |> sorted_stable_ids(),
      "invalid_contact_input_ids" =>
        invalid_input_row_contact_ids(
          report,
          "invalid_contact_inputs",
          "invalid_contact_input_ids"
        ),
      "invalid_selected_contact_input_ids" =>
        invalid_input_row_contact_ids(
          report,
          "invalid_selected_contact_inputs",
          "invalid_selected_contact_input_ids"
        ),
      "invalid_policy_required_downlink_station_ids" =>
        report_string_values(report, "invalid_policy_required_downlink_station_ids"),
      "ground_station_ids" => row_ground_station_ids(rows),
      "shortfall_ground_station_ids" =>
        station_ids_by_row_value(rows, "downlink_requirement_status", "shortfall"),
      "actual_shortfall_ground_station_ids" =>
        station_ids_by_row_value(rows, "actual_downlink_requirement_status", "shortfall"),
      "selected_downlink_shortfall_mb_by_ground_station_id" =>
        row_numeric_values_by_station(rows, "selected_downlink_shortfall_mb"),
      "actual_downlink_shortfall_mb_by_ground_station_id" =>
        row_numeric_values_by_station(rows, "actual_downlink_shortfall_mb"),
      "ground_station_ids_by_station_availability" =>
        row_station_ids_by_station_availability(rows),
      "ground_station_ids_by_reservation_match_status" =>
        row_station_ids_by_list_field(rows, "station_reservation_match_statuses"),
      "ground_station_ids_by_reservation_status" =>
        row_station_ids_by_list_field(rows, "station_reservation_statuses"),
      "ground_station_ids_by_reserved_by" =>
        row_station_ids_by_list_field(rows, "station_reserved_bys"),
      "station_calendar_entry_ids_by_ground_station_id" =>
        row_station_calendar_entry_ids_by_station(rows),
      "station_calendar_provider_ids_by_ground_station_id" =>
        row_station_calendar_provider_ids_by_station(rows),
      "station_calendar_provider_entry_ids_by_ground_station_id" =>
        row_station_calendar_provider_entry_ids_by_station(rows),
      "station_reservation_ids_by_ground_station_id" =>
        row_station_reservation_ids_by_station(rows),
      "ignored_contact_ids_by_ground_station_id" =>
        row_ids_by_station(rows, "ignored_contact_ids"),
      "selected_contact_ids_by_ground_station_id" =>
        row_ids_by_station(rows, "selected_contact_ids"),
      "capacity_adjusted_throughput_mb_by_ground_station_id" =>
        row_numeric_values_by_station(rows, "capacity_adjusted_throughput_mb"),
      "selected_capacity_adjusted_throughput_mb_by_ground_station_id" =>
        row_numeric_values_by_station(rows, "selected_capacity_adjusted_throughput_mb"),
      "unused_capacity_adjusted_throughput_mb_by_ground_station_id" =>
        row_numeric_values_by_station(rows, "unused_capacity_adjusted_throughput_mb"),
      "required_downlink_contact_ids_by_ground_station_id" =>
        row_ids_by_station(rows, "required_downlink_contact_ids"),
      "actual_throughput_contact_ids_by_ground_station_id" =>
        row_ids_by_station(rows, "actual_throughput_contact_ids"),
      "actual_completion_contact_ids_by_ground_station_id" =>
        row_ids_by_station(rows, "actual_completion_contact_ids"),
      "unmatched_actual_throughput_contact_ids_by_ground_station_id" =>
        row_ids_by_station(rows, "unmatched_actual_throughput_contact_ids"),
      "ambiguous_actual_throughput_contact_ids_by_ground_station_id" =>
        row_ids_by_station(rows, "ambiguous_actual_throughput_contact_ids"),
      "unmatched_actual_completion_contact_ids_by_ground_station_id" =>
        row_ids_by_station(rows, "unmatched_actual_completion_contact_ids"),
      "ambiguous_actual_completion_contact_ids_by_ground_station_id" =>
        row_ids_by_station(rows, "ambiguous_actual_completion_contact_ids"),
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_provider_reservation_or_schedule_mutation",
        "source" => "link_capacity_report.v1",
        "operator_authority" => "not_granted_by_summary",
        "station_unavailable_aliases" => context.station_unavailable_aliases,
        "station_availability_precedence" => context.station_availability_precedence,
        "station_capacity_value_paths" => context.capacity_value_path_assumptions,
        "source_station_capacity_value_paths" => context.capacity_value_path_assumptions,
        "provider_direction_aliases" => context.provider_direction_aliases
      }
    }
    |> compact_map()
  end

  defp row_ground_station_ids(rows) do
    rows
    |> Enum.map(& &1["ground_station_id"])
    |> Enum.map(&stable_id_or_nil/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp row_scalar_count_sum(rows, field) do
    Enum.reduce(rows, 0, fn row, total ->
      case Map.get(row, field) do
        count when is_integer(count) and count >= 0 -> total + count
        count when is_float(count) and count >= 0.0 -> total + trunc(count)
        _count -> total
      end
    end)
  end

  defp row_numeric_sum(rows, field) do
    rows
    |> Enum.map(&(Map.get(&1, field) |> numeric_value()))
    |> Enum.filter(&is_number/1)
    |> Enum.sum()
  end

  defp row_list_count(rows, field) do
    rows
    |> row_list_values(field, :stable_id)
    |> List.wrap()
    |> length()
  end

  defp report_list_count(report, rows_field, ids_field) do
    case Map.get(report, rows_field) do
      values when is_list(values) -> length(values)
      _values -> length(Map.get(report, ids_field) || [])
    end
  end

  defp invalid_input_row_contact_ids(report, rows_field, ids_field) do
    case Map.get(report, rows_field) do
      rows when is_list(rows) ->
        rows
        |> Enum.filter(&is_map/1)
        |> Enum.map(&Map.get(&1, "contact_id"))
        |> sorted_stable_ids()

      _rows ->
        report
        |> Map.get(ids_field, [])
        |> sorted_stable_ids()
    end
  end

  defp report_string_values(report, field) do
    report
    |> Map.get(field, [])
    |> normalized_string_values()
    |> List.wrap()
  end

  defp station_ids_by_row_value(rows, field, value) do
    rows
    |> Enum.filter(&(Map.get(&1, field) == value))
    |> row_ground_station_ids()
  end

  defp row_station_ids_by_station_availability(rows) do
    rows
    |> Enum.group_by(&station_availability/1, & &1["ground_station_id"])
    |> Enum.reject(fn {availability, station_ids} ->
      is_nil(availability) or Enum.all?(station_ids, &is_nil(stable_id_or_nil(&1)))
    end)
    |> Map.new(fn {availability, station_ids} ->
      {availability, sorted_stable_ids(station_ids)}
    end)
  end

  defp row_station_ids_by_list_field(rows, field) do
    rows
    |> Enum.flat_map(fn row ->
      row_values_by_list_field(row, field)
      |> Enum.map(&{&1, row["ground_station_id"]})
    end)
    |> Enum.group_by(fn {field_value, _station_id} -> field_value end, fn {_field_value,
                                                                           station_id} ->
      station_id
    end)
    |> Enum.reject(fn {field_value, station_ids} ->
      is_nil(field_value) or Enum.all?(station_ids, &is_nil(stable_id_or_nil(&1)))
    end)
    |> Map.new(fn {field_value, station_ids} ->
      {field_value, sorted_stable_ids(station_ids)}
    end)
  end

  defp row_values_by_list_field(row, "station_reservation_match_statuses"),
    do: row_station_reservation_match_statuses(row)

  defp row_values_by_list_field(row, "station_reservation_statuses"),
    do: row_station_reservation_statuses([row]) || []

  defp row_values_by_list_field(row, "station_reserved_bys"),
    do: row_station_reserved_bys([row]) || []

  defp row_values_by_list_field(row, field) do
    row
    |> Map.get(field, [])
    |> List.wrap()
  end

  defp row_station_calendar_entry_ids_by_station(rows) do
    rows
    |> Enum.map(fn row ->
      row_ids =
        [
          Map.get(row, "station_calendar_entry_ids"),
          source_station_calendar_values(row["source_station_calendar_entry"], [
            "id",
            "entry_id",
            "station_calendar_entry_id"
          ]),
          source_station_calendar_values(row["source_station_calendar_overlaps"], [
            "id",
            "entry_id",
            "station_calendar_entry_id"
          ])
        ]
        |> List.flatten()
        |> sorted_stable_ids()

      {row["ground_station_id"], row_ids}
    end)
    |> row_ids_by_station_entries()
  end

  defp row_station_calendar_provider_ids_by_station(rows) do
    rows
    |> Enum.map(fn row ->
      row_ids =
        [
          Map.get(row, "station_calendar_provider_ids"),
          source_station_calendar_values(row["source_station_calendar_entry"], [
            "provider_id",
            "station_calendar_provider_id"
          ]),
          source_station_calendar_values(row["source_station_calendar_overlaps"], [
            "provider_id",
            "station_calendar_provider_id"
          ])
        ]
        |> List.flatten()
        |> sorted_stable_ids()

      {row["ground_station_id"], row_ids}
    end)
    |> row_ids_by_station_entries()
  end

  defp row_station_calendar_provider_entry_ids_by_station(rows) do
    rows
    |> Enum.map(fn row ->
      row_ids =
        [
          Map.get(row, "station_calendar_provider_entry_ids"),
          source_station_calendar_values(row["source_station_calendar_entry"], [
            "provider_entry_id",
            "station_calendar_provider_entry_id"
          ]),
          source_station_calendar_values(row["source_station_calendar_overlaps"], [
            "provider_entry_id",
            "station_calendar_provider_entry_id"
          ])
        ]
        |> List.flatten()
        |> sorted_stable_ids()

      {row["ground_station_id"], row_ids}
    end)
    |> row_ids_by_station_entries()
  end

  defp row_station_reservation_ids_by_station(rows) do
    rows
    |> Enum.map(fn row ->
      {row["ground_station_id"], row_station_reservation_ids([row]) || []}
    end)
    |> row_ids_by_station_entries()
  end

  defp row_ids_by_station(rows, field) do
    rows
    |> Enum.map(fn row ->
      contact_ids =
        row
        |> Map.get(field, [])
        |> List.wrap()
        |> Enum.map(&stable_id_or_nil/1)
        |> Enum.reject(&is_nil/1)
        |> Enum.uniq()
        |> Enum.sort()

      {row["ground_station_id"], contact_ids}
    end)
    |> Enum.reject(fn {ground_station_id, contact_ids} ->
      is_nil(stable_id_or_nil(ground_station_id)) or contact_ids == []
    end)
    |> Map.new(fn {ground_station_id, contact_ids} ->
      {stable_id_or_nil(ground_station_id), contact_ids}
    end)
  end

  defp row_numeric_values_by_station(rows, field) do
    rows
    |> Enum.reduce(%{}, fn row, totals ->
      station_id = stable_id_or_nil(row["ground_station_id"])
      value = row |> Map.get(field) |> numeric_value()

      if is_nil(station_id) or is_nil(value) do
        totals
      else
        Map.update(totals, station_id, value, &(&1 + value))
      end
    end)
  end

  defp row_ids_by_station_entries(entries) do
    entries
    |> Enum.reject(fn {ground_station_id, row_ids} ->
      is_nil(stable_id_or_nil(ground_station_id)) or row_ids == []
    end)
    |> Enum.reduce(%{}, fn {ground_station_id, row_ids}, ids_by_station ->
      station_id = stable_id_or_nil(ground_station_id)

      Map.update(ids_by_station, station_id, row_ids, fn existing_ids ->
        sorted_stable_ids(existing_ids ++ row_ids)
      end)
    end)
  end

  defp sorted_stable_ids(values) do
    values
    |> Enum.map(&stable_id_or_nil/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp row_list_values(rows, field, :stable_id) do
    rows
    |> Enum.flat_map(&List.wrap(Map.get(&1, field)))
    |> Enum.map(&stable_id_or_nil/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
    |> empty_list_to_nil()
  end

  defp row_station_calendar_entry_ids(rows) do
    row_station_calendar_ids(rows, "station_calendar_entry_ids", [
      "id",
      "entry_id",
      "station_calendar_entry_id"
    ])
  end

  defp row_station_calendar_provider_ids(rows) do
    row_station_calendar_ids(rows, "station_calendar_provider_ids", [
      "provider_id",
      "station_calendar_provider_id"
    ])
  end

  defp row_station_calendar_provider_entry_ids(rows) do
    row_station_calendar_ids(rows, "station_calendar_provider_entry_ids", [
      "provider_entry_id",
      "station_calendar_provider_entry_id"
    ])
  end

  defp row_station_calendar_ids(rows, row_field, source_fields) do
    [
      row_list_values(rows, row_field, :stable_id),
      row_source_station_calendar_values(rows, source_fields)
    ]
    |> List.flatten()
    |> sorted_stable_ids()
    |> empty_list_to_nil()
  end

  defp row_station_reservation_ids(rows), do: StationReservationEvidence.row_ids(rows)

  defp row_station_reservation_expires_at_s(rows),
    do: StationReservationEvidence.row_expires_at_s(rows)

  defp row_station_reserved_bys(rows), do: StationReservationEvidence.row_reserved_bys(rows)

  defp row_station_reservation_statuses(rows),
    do: StationReservationEvidence.row_statuses(rows)

  defp row_station_reservation_match_status_counts(rows),
    do: StationReservationEvidence.row_match_status_counts(rows)

  defp row_station_reservation_match_statuses(row),
    do: StationReservationEvidence.row_match_statuses(row)

  defp row_source_station_calendar_values(rows, source_fields) do
    rows
    |> Enum.flat_map(fn row ->
      source_station_calendar_values(row["source_station_calendar_entry"], source_fields) ++
        source_station_calendar_values(row["source_station_calendar_overlaps"], source_fields)
    end)
  end

  defp row_count_map(rows, field) do
    rows
    |> Enum.flat_map(fn row ->
      case Map.get(row, field) do
        counts when is_map(counts) -> Map.to_list(counts)
        _counts -> []
      end
    end)
    |> Enum.reduce(%{}, fn
      {key, count}, acc when is_number(count) ->
        Map.update(acc, to_string(key), count, &(&1 + count))

      _entry, acc ->
        acc
    end)
    |> empty_map_to_nil()
  end

  defp source_station_calendar_values(sources, fields),
    do: StationReservationEvidence.source_values(sources, fields)

  defp normalized_string_values(values),
    do: StationReservationEvidence.normalized_string_values(values)

  defp station_availability(value), do: StationAvailability.value(value)
  defp stable_id_or_nil(value), do: ContactIdentity.stable_id_or_nil(value)
  defp numeric_value(value), do: ContactNormalization.numeric_value(value)

  defp normalize_station_calendar_status_fields(row, context) do
    ContactNormalization.normalize_station_calendar_status_fields(
      row,
      context.station_unavailable_aliases,
      context.provider_direction_aliases
    )
  end

  defp stringify_keys(value), do: ContactNormalization.stringify_keys(value)
  defp compact_map(map), do: ContactNormalization.compact_map(map)
  defp empty_map_to_nil(map) when map == %{}, do: nil
  defp empty_map_to_nil(map), do: map
  defp empty_list_to_nil([]), do: nil
  defp empty_list_to_nil(values), do: values
end
