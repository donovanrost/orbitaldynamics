defmodule OrbitalDynamics.Schema.ResourceProjectionFlowSummaryCountContracts do
  @moduledoc false

  alias OrbitalDynamics.Schema.PrimitiveValidation

  def validate(issues, path, summary) do
    projected_rows =
      summary
      |> Map.get("projected_resources", [])
      |> case do
        rows when is_list(rows) -> Enum.filter(rows, &is_map/1)
        _rows -> []
      end

    flow_rows =
      summary
      |> Map.get("activity_resource_flow", [])
      |> case do
        rows when is_list(rows) -> Enum.filter(rows, &is_map/1)
        _rows -> []
      end

    invalid_activity_ids = list_or_empty(Map.get(summary, "invalid_activity_input_ids"))
    invalid_summary_ids = list_or_empty(Map.get(summary, "invalid_resource_summary_input_ids"))
    pressure_rows = Enum.filter(projected_rows, &pressure_row?/1)
    pressure_types = pressure_types(projected_rows, flow_rows)
    ignored_rows = ignored_rows(flow_rows)
    latency_review_ids = latency_review_activity_ids(flow_rows)
    latency_review_count = length(latency_review_ids)
    latency_evidence_count = latency_evidence_count(flow_rows)

    invalid_input_count = length(invalid_activity_ids) + length(invalid_summary_ids)

    expected_flow_status =
      if pressure_rows == [] and invalid_input_count == 0 and latency_review_count == 0 do
        "clear"
      else
        "review_required"
      end

    issues
    |> PrimitiveValidation.expect_field_equals(
      path,
      summary,
      "invalid_activity_input_count",
      length(invalid_activity_ids),
      "must equal invalid_activity_input_ids count"
    )
    |> PrimitiveValidation.expect_field_equals(
      path,
      summary,
      "invalid_resource_summary_input_count",
      length(invalid_summary_ids),
      "must equal invalid_resource_summary_input_ids count"
    )
    |> PrimitiveValidation.expect_field_equals(
      path,
      summary,
      "activity_count",
      integer_or_zero(Map.get(summary, "valid_activity_count")) + length(invalid_activity_ids),
      "must equal valid_activity_count plus invalid_activity_input_ids count"
    )
    |> PrimitiveValidation.expect_field_equals(
      path,
      summary,
      "input_resource_summary_count",
      integer_or_zero(Map.get(summary, "valid_resource_summary_count")) +
        length(invalid_summary_ids),
      "must equal valid_resource_summary_count plus invalid_resource_summary_input_ids count"
    )
    |> PrimitiveValidation.expect_field_equals(
      path,
      summary,
      "projected_resource_count",
      length(projected_rows),
      "must equal projected_resources count"
    )
    |> PrimitiveValidation.expect_field_equals(
      path,
      summary,
      "valid_resource_summary_count",
      length(projected_rows),
      "must equal projected_resources count"
    )
    |> PrimitiveValidation.expect_field_equals(
      path,
      summary,
      "flow_row_count",
      length(flow_rows),
      "must equal activity_resource_flow row count"
    )
    |> PrimitiveValidation.expect_field_equals(
      path,
      summary,
      "ignored_activity_count",
      length(ignored_rows),
      "must equal ignored activity_resource_flow row count"
    )
    |> PrimitiveValidation.expect_field_equals(
      path,
      summary,
      "ignored_activity_reason_counts",
      ignored_activity_reason_counts(ignored_rows),
      "must equal ignored activity_resource_flow reason counts"
    )
    |> PrimitiveValidation.expect_field_equals(
      path,
      summary,
      "ignored_activity_ids",
      ignored_activity_ids(ignored_rows),
      "must equal ignored activity_resource_flow activity IDs"
    )
    |> PrimitiveValidation.expect_field_equals(
      path,
      summary,
      "ignored_activity_ids_by_reason",
      ignored_activity_ids_by_reason(ignored_rows),
      "must equal ignored activity_resource_flow activity IDs by reason"
    )
    |> PrimitiveValidation.expect_field_equals(
      path,
      summary,
      "resource_flow_status",
      expected_flow_status
    )
    |> PrimitiveValidation.expect_field_equals(
      path,
      summary,
      "resource_pressure_status",
      if(pressure_rows == [], do: "clear", else: "review_required")
    )
    |> PrimitiveValidation.expect_field_equals(
      path,
      summary,
      "resource_pressure_count",
      length(pressure_rows),
      "must equal projected resource pressure row count"
    )
    |> PrimitiveValidation.expect_field_equals(
      path,
      summary,
      "resource_pressure_types",
      pressure_types,
      "must equal row-derived resource_pressure_types"
    )
    |> PrimitiveValidation.expect_field_equals(
      path,
      summary,
      "resource_pressure_spacecraft_ids",
      Enum.map(pressure_rows, &Map.get(&1, "spacecraft_id")) |> sorted_stable_values(),
      "must equal row-derived resource_pressure_spacecraft_ids"
    )
    |> PrimitiveValidation.expect_field_equals(
      path,
      summary,
      "resource_pressure_spacecraft_ids_by_type",
      spacecraft_ids_by_type(projected_rows, flow_rows),
      "must equal row-derived resource_pressure_spacecraft_ids_by_type"
    )
    |> PrimitiveValidation.expect_field_equals(
      path,
      summary,
      "resource_pressure_activity_ids_by_type",
      activity_ids_by_type(flow_rows),
      "must equal row-derived resource_pressure_activity_ids_by_type"
    )
    |> PrimitiveValidation.expect_field_equals(
      path,
      summary,
      "resource_pressure_ground_station_ids_by_type",
      ground_station_ids_by_type(flow_rows),
      "must equal row-derived resource_pressure_ground_station_ids_by_type"
    )
    |> PrimitiveValidation.expect_field_equals(
      path,
      summary,
      "resource_pressure_source_window_ids_by_type",
      source_window_ids_by_type(flow_rows),
      "must equal row-derived resource_pressure_source_window_ids_by_type"
    )
    |> PrimitiveValidation.expect_field_equals(
      path,
      summary,
      "resource_pressure_station_calendar_entry_ids_by_type",
      station_calendar_entry_ids_by_type(flow_rows),
      "must equal row-derived resource_pressure_station_calendar_entry_ids_by_type"
    )
    |> PrimitiveValidation.expect_field_equals(
      path,
      summary,
      "resource_pressure_station_calendar_provider_ids_by_type",
      station_calendar_provider_ids_by_type(flow_rows),
      "must equal row-derived resource_pressure_station_calendar_provider_ids_by_type"
    )
    |> PrimitiveValidation.expect_field_equals(
      path,
      summary,
      "resource_pressure_station_calendar_provider_entry_ids_by_type",
      station_calendar_provider_entry_ids_by_type(flow_rows),
      "must equal row-derived resource_pressure_station_calendar_provider_entry_ids_by_type"
    )
    |> PrimitiveValidation.expect_field_equals(
      path,
      summary,
      "resource_pressure_station_calendar_directions_by_type",
      station_calendar_directions_by_type(flow_rows),
      "must equal row-derived resource_pressure_station_calendar_directions_by_type"
    )
    |> PrimitiveValidation.expect_field_equals(
      path,
      summary,
      "resource_pressure_capacity_fractions_by_type",
      capacity_fractions_by_type(flow_rows),
      "must equal row-derived resource_pressure_capacity_fractions_by_type"
    )
    |> PrimitiveValidation.expect_field_equals(
      path,
      summary,
      "total_storage_produced_mb",
      sum_flow_number(flow_rows, "storage_produced_mb"),
      "must equal activity_resource_flow storage_produced_mb sum"
    )
    |> PrimitiveValidation.expect_field_equals(
      path,
      summary,
      "total_planned_downlink_mb",
      sum_flow_number(flow_rows, "planned_downlink_mb"),
      "must equal activity_resource_flow planned_downlink_mb sum"
    )
    |> PrimitiveValidation.expect_field_equals(
      path,
      summary,
      "total_storage_limited_downlinked_mb",
      sum_flow_number(flow_rows, "downlinked_mb"),
      "must equal activity_resource_flow downlinked_mb sum"
    )
    |> PrimitiveValidation.expect_field_equals(
      path,
      summary,
      "total_unused_downlink_capacity_mb",
      sum_flow_number(flow_rows, "unused_downlink_capacity_mb"),
      "must equal activity_resource_flow unused_downlink_capacity_mb sum"
    )
    |> PrimitiveValidation.expect_field_equals(
      path,
      summary,
      "total_storage_overflow_mb",
      sum_flow_number(flow_rows, "storage_overflow_mb"),
      "must equal activity_resource_flow storage_overflow_mb sum"
    )
    |> PrimitiveValidation.expect_field_equals(
      path,
      summary,
      "total_downlink_shortfall_mb",
      sum_flow_number(flow_rows, "downlink_shortfall_mb"),
      "must equal activity_resource_flow downlink_shortfall_mb sum"
    )
    |> PrimitiveValidation.expect_field_equals(
      path,
      summary,
      "actual_data_volume_evidence_count",
      actual_data_volume_evidence_count(flow_rows),
      "must equal activity_resource_flow actual_data_volume_mb evidence count"
    )
    |> PrimitiveValidation.expect_field_equals(
      path,
      summary,
      "total_actual_data_volume_mb",
      sum_flow_number(flow_rows, "actual_data_volume_mb"),
      "must equal activity_resource_flow actual_data_volume_mb sum"
    )
    |> PrimitiveValidation.expect_field_equals(
      path,
      summary,
      "total_data_volume_delta_mb",
      sum_flow_number(flow_rows, "data_volume_delta_mb"),
      "must equal activity_resource_flow data_volume_delta_mb sum"
    )
    |> PrimitiveValidation.expect_field_equals(
      path,
      summary,
      "actual_data_volume_under_delivered_activity_ids",
      data_volume_variance_activity_ids(flow_rows, :under_delivered),
      "must equal activity_resource_flow under-delivered actual data-volume activity IDs"
    )
    |> PrimitiveValidation.expect_field_equals(
      path,
      summary,
      "actual_data_volume_over_delivered_activity_ids",
      data_volume_variance_activity_ids(flow_rows, :over_delivered),
      "must equal activity_resource_flow over-delivered actual data-volume activity IDs"
    )
    |> PrimitiveValidation.expect_field_equals(
      path,
      summary,
      "actual_data_volume_exact_activity_ids",
      data_volume_variance_activity_ids(flow_rows, :exact),
      "must equal activity_resource_flow exact actual data-volume activity IDs"
    )
    |> PrimitiveValidation.expect_field_equals(
      path,
      summary,
      "total_projected_storage_remaining_mb",
      sum_remaining(projected_rows, "storage_capacity_mb", "projected_storage_used_mb"),
      "must equal projected_resources storage remaining sum"
    )
    |> PrimitiveValidation.expect_field_equals(
      path,
      summary,
      "minimum_projected_storage_remaining_mb",
      min_remaining(projected_rows, "storage_capacity_mb", "projected_storage_used_mb"),
      "must equal projected_resources minimum storage remaining"
    )
    |> PrimitiveValidation.expect_field_equals(
      path,
      summary,
      "total_projected_downlink_remaining_mb",
      sum_remaining(projected_rows, "downlink_capacity_mb", "estimated_downlink_mb"),
      "must equal projected_resources downlink remaining sum"
    )
    |> PrimitiveValidation.expect_field_equals(
      path,
      summary,
      "minimum_projected_downlink_remaining_mb",
      min_remaining(projected_rows, "downlink_capacity_mb", "estimated_downlink_mb"),
      "must equal projected_resources minimum downlink remaining"
    )
    |> PrimitiveValidation.expect_field_equals(
      path,
      summary,
      "latency_status",
      latency_status(latency_evidence_count, latency_review_count)
    )
    |> PrimitiveValidation.expect_field_equals(
      path,
      summary,
      "latency_evidence_count",
      latency_evidence_count,
      "must equal activity_resource_flow latency evidence count"
    )
    |> PrimitiveValidation.expect_field_equals(
      path,
      summary,
      "latency_review_count",
      latency_review_count,
      "must equal activity_resource_flow late latency count"
    )
    |> PrimitiveValidation.expect_field_equals(
      path,
      summary,
      "latency_review_activity_ids",
      latency_review_ids,
      "must equal activity_resource_flow late activity IDs"
    )
    |> PrimitiveValidation.expect_field_equals(
      path,
      summary,
      "max_planned_latency_s",
      max_optional_flow_number(flow_rows, "planned_latency_s")
    )
    |> PrimitiveValidation.expect_field_equals(
      path,
      summary,
      "max_actual_latency_s",
      max_optional_flow_number(flow_rows, "actual_latency_s")
    )
    |> PrimitiveValidation.expect_field_equals(
      path,
      summary,
      "total_battery_energy_consumed_wh",
      sum_flow_number(flow_rows, "battery_energy_consumed_wh"),
      "must equal activity_resource_flow battery_energy_consumed_wh sum"
    )
    |> PrimitiveValidation.expect_field_equals(
      path,
      summary,
      "total_battery_energy_generated_wh",
      sum_flow_number(flow_rows, "battery_energy_generated_wh"),
      "must equal activity_resource_flow battery_energy_generated_wh sum"
    )
    |> PrimitiveValidation.expect_field_equals(
      path,
      summary,
      "net_battery_energy_delta_wh",
      sum_flow_number(flow_rows, "battery_energy_delta_wh"),
      "must equal activity_resource_flow battery_energy_delta_wh sum"
    )
    |> PrimitiveValidation.expect_field_equals(
      path,
      summary,
      "peak_battery_overuse_wh",
      max_flow_number(flow_rows, "battery_overuse_wh"),
      "must equal activity_resource_flow peak battery_overuse_wh"
    )
  end

  defp pressure_row?(row) do
    Map.get(row, "resource_pressure_types", []) != [] or
      Map.get(row, "resource_pressure_status") in [
        "review_required",
        "storage_overflow",
        "downlink_shortfall",
        "battery_depletion"
      ]
  end

  defp pressure_types(projected_rows, flow_rows) do
    projected_types =
      projected_rows
      |> Enum.flat_map(fn
        %{} = row -> Map.get(row, "resource_pressure_types", [])
        _row -> []
      end)

    flow_types =
      flow_rows
      |> Enum.flat_map(&pressure_kinds/1)

    (projected_types ++ flow_types)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp ignored_rows(flow_rows) do
    OrbitalDynamics.Schema.ResourceProjectionFlowSummaryIgnoredContracts.rows(flow_rows)
  end

  defp ignored_activity_ids(rows) do
    OrbitalDynamics.Schema.ResourceProjectionFlowSummaryIgnoredContracts.activity_ids(
      rows,
      ignored_contract_callbacks()
    )
  end

  defp ignored_activity_reason_counts(rows) do
    OrbitalDynamics.Schema.ResourceProjectionFlowSummaryIgnoredContracts.reason_counts(rows)
  end

  defp ignored_activity_ids_by_reason(rows) do
    OrbitalDynamics.Schema.ResourceProjectionFlowSummaryIgnoredContracts.activity_ids_by_reason(
      rows,
      ignored_contract_callbacks()
    )
  end

  defp ignored_contract_callbacks do
    [
      sorted_stable_values: &sorted_stable_values/1,
      stable_values_by_key: &stable_values_by_key/1
    ]
  end

  defp actual_data_volume_evidence_count(flow_rows) do
    OrbitalDynamics.Schema.ResourceProjectionFlowSummaryDataVolumeContracts.evidence_count(
      flow_rows
    )
  end

  defp data_volume_variance_activity_ids(flow_rows, variance) do
    OrbitalDynamics.Schema.ResourceProjectionFlowSummaryDataVolumeContracts.variance_activity_ids(
      flow_rows,
      variance,
      data_volume_contract_callbacks()
    )
  end

  defp data_volume_contract_callbacks do
    [
      sorted_stable_values: &sorted_stable_values/1
    ]
  end

  defp latency_status(evidence_count, review_count) do
    OrbitalDynamics.Schema.ResourceProjectionFlowSummaryLatencyContracts.status(
      evidence_count,
      review_count
    )
  end

  defp latency_evidence_count(flow_rows) do
    OrbitalDynamics.Schema.ResourceProjectionFlowSummaryLatencyContracts.evidence_count(flow_rows)
  end

  defp latency_review_activity_ids(flow_rows) do
    OrbitalDynamics.Schema.ResourceProjectionFlowSummaryLatencyContracts.review_activity_ids(
      flow_rows,
      latency_contract_callbacks()
    )
  end

  defp latency_contract_callbacks do
    [
      sorted_stable_values: &sorted_stable_values/1
    ]
  end

  defp spacecraft_ids_by_type(projected_rows, flow_rows) do
    projected_pairs =
      Enum.flat_map(projected_rows, fn
        %{} = row ->
          row
          |> Map.get("resource_pressure_types", [])
          |> Enum.map(&{&1, Map.get(row, "spacecraft_id")})

        _row ->
          []
      end)

    flow_pairs =
      Enum.flat_map(flow_rows, fn row ->
        Enum.map(pressure_kinds(row), &{&1, Map.get(row, "spacecraft_id")})
      end)

    stable_values_by_key(projected_pairs ++ flow_pairs)
  end

  defp activity_ids_by_type(flow_rows) do
    flow_rows
    |> Enum.flat_map(fn row ->
      Enum.map(pressure_kinds(row), &{&1, Map.get(row, "activity_id")})
    end)
    |> stable_values_by_key()
  end

  defp ground_station_ids_by_type(flow_rows) do
    flow_rows
    |> Enum.flat_map(fn
      %{} = row ->
        Enum.map(pressure_kinds(row), fn pressure_type ->
          {pressure_type, Map.get(row, "ground_station_id")}
        end)

      _row ->
        []
    end)
    |> stable_values_by_key()
  end

  defp source_window_ids_by_type(flow_rows) do
    flow_rows
    |> Enum.flat_map(fn
      %{} = row ->
        Enum.map(pressure_kinds(row), fn pressure_type ->
          {pressure_type, Map.get(row, "source_window_id")}
        end)

      _row ->
        []
    end)
    |> stable_values_by_key()
  end

  defp station_calendar_entry_ids_by_type(flow_rows) do
    OrbitalDynamics.Schema.ResourceProjectionStationCalendarContextContracts.entry_ids_by_type(
      flow_rows,
      station_calendar_context_callbacks()
    )
  end

  defp station_calendar_provider_ids_by_type(flow_rows) do
    OrbitalDynamics.Schema.ResourceProjectionStationCalendarContextContracts.provider_ids_by_type(
      flow_rows,
      station_calendar_context_callbacks()
    )
  end

  defp station_calendar_provider_entry_ids_by_type(flow_rows) do
    OrbitalDynamics.Schema.ResourceProjectionStationCalendarContextContracts.provider_entry_ids_by_type(
      flow_rows,
      station_calendar_context_callbacks()
    )
  end

  defp station_calendar_directions_by_type(flow_rows) do
    OrbitalDynamics.Schema.ResourceProjectionStationCalendarContextContracts.directions_by_type(
      flow_rows,
      station_calendar_context_callbacks()
    )
  end

  defp station_calendar_context_callbacks do
    [
      resource_projection_pressure_kinds: &pressure_kinds/1,
      stable_values_by_key: &stable_values_by_key/1
    ]
  end

  defp capacity_fractions_by_type(flow_rows) do
    flow_rows
    |> Enum.flat_map(fn
      %{} = row ->
        case Map.get(row, "capacity_fraction") do
          value when is_number(value) ->
            Enum.map(pressure_kinds(row), &{&1, value})

          _value ->
            []
        end

      _row ->
        []
    end)
    |> number_values_by_key()
  end

  defp pressure_kinds(row) do
    []
    |> maybe_add_pressure_kind(row, "storage_overflow", "storage_overflow_mb")
    |> maybe_add_pressure_kind(row, "downlink_shortfall", "downlink_shortfall_mb")
    |> maybe_add_pressure_kind(row, "battery_depletion", "battery_overuse_wh")
    |> maybe_add_availability_pressure_kind(row)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp maybe_add_pressure_kind(types, row, type, field) do
    case Map.get(row, field) do
      value when is_number(value) and value > 0.0 -> [type | types]
      _value -> types
    end
  end

  defp maybe_add_availability_pressure_kind(types, %{"resource_effect_reason" => reason})
       when reason in [
              "spacecraft_unavailable",
              "payload_unavailable",
              "spacecraft_degraded_payload_unavailable",
              "activity_type_suppressed_by_resource_summary",
              "activity_type_incompatible_with_resource_summary",
              "antenna_unavailable"
            ],
       do: [reason | types]

  defp maybe_add_availability_pressure_kind(types, _row), do: types

  defp sum_flow_number(flow_rows, field) do
    OrbitalDynamics.Schema.ResourceProjectionNumericContracts.sum_flow_number(flow_rows, field)
  end

  defp sum_remaining(rows, capacity_field, used_or_demand_field) do
    OrbitalDynamics.Schema.ResourceProjectionNumericContracts.sum_remaining(
      rows,
      capacity_field,
      used_or_demand_field
    )
  end

  defp min_remaining(rows, capacity_field, used_or_demand_field) do
    OrbitalDynamics.Schema.ResourceProjectionNumericContracts.min_remaining(
      rows,
      capacity_field,
      used_or_demand_field
    )
  end

  defp max_flow_number(flow_rows, field) do
    OrbitalDynamics.Schema.ResourceProjectionNumericContracts.max_flow_number(flow_rows, field)
  end

  defp max_optional_flow_number(flow_rows, field) do
    OrbitalDynamics.Schema.ResourceProjectionNumericContracts.max_optional_flow_number(
      flow_rows,
      field
    )
  end

  defp integer_or_zero(value),
    do: OrbitalDynamics.Schema.CollectionAggregation.integer_or_zero(value)

  defp list_or_empty(values) when is_list(values), do: values
  defp list_or_empty(_values), do: []

  defp stable_values_by_key(pairs) do
    pairs
    |> Enum.reject(fn {key, value} -> key in [nil, ""] or value in [nil, ""] end)
    |> Enum.group_by(fn {key, _value} -> key end, fn {_key, value} -> value end)
    |> Map.new(fn {key, values} -> {key, sorted_stable_values(values)} end)
  end

  defp number_values_by_key(pairs) do
    pairs
    |> Enum.reject(fn {key, value} -> key in [nil, ""] or not is_number(value) end)
    |> Enum.group_by(fn {key, _value} -> key end, fn {_key, value} -> value end)
    |> Map.new(fn {key, values} -> {key, values |> Enum.uniq() |> Enum.sort()} end)
  end

  defp sorted_stable_values(values) do
    values
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.map(&to_string/1)
    |> Enum.uniq()
    |> Enum.sort()
  end
end
