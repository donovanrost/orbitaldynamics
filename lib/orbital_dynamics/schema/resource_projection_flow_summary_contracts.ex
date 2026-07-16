defmodule OrbitalDynamics.Schema.ResourceProjectionFlowSummaryContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.CollectionValidation,
    only: [validate_rows: 4, validate_string_list_map: 4]

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      expect_equal: 5,
      expect_non_negative_integer: 4,
      expect_number: 4,
      expect_one_of: 5,
      expect_optional_non_negative_integer: 4,
      expect_optional_number: 4,
      expect_optional_one_of: 5,
      expect_optional_type: 5,
      expect_type: 5,
      require_fields: 4,
      validate_non_negative_integer_count_map: 3,
      validate_number_array_map: 3,
      validate_optional_exact_model_limits: 5,
      validate_string_list_items: 4
    ]

  import OrbitalDynamics.Schema.StableIdValidation,
    only: [validate_optional_stable_id_list: 4, validate_stable_id_array_map: 3]

  def validate(
        issues,
        path,
        summary,
        model_limits,
        subsystem_assumptions_validator,
        projected_resource_validator,
        flow_row_validator,
        counts_validator
      )
      when is_function(subsystem_assumptions_validator, 3) and
             is_function(projected_resource_validator, 3) and
             is_function(flow_row_validator, 3) and
             is_function(counts_validator, 3) do
    issues
    |> require_fields(path, summary, [
      "schema_contract",
      "schema_version",
      "model",
      "activity_count",
      "valid_activity_count",
      "invalid_activity_input_count",
      "invalid_activity_input_ids",
      "input_resource_summary_count",
      "valid_resource_summary_count",
      "invalid_resource_summary_input_count",
      "invalid_resource_summary_input_ids",
      "projected_resource_count",
      "flow_row_count",
      "resource_flow_status",
      "resource_pressure_status",
      "resource_pressure_count",
      "resource_pressure_types",
      "resource_pressure_spacecraft_ids",
      "resource_pressure_spacecraft_ids_by_type",
      "resource_pressure_activity_ids_by_type",
      "total_storage_produced_mb",
      "total_planned_downlink_mb",
      "total_storage_limited_downlinked_mb",
      "total_unused_downlink_capacity_mb",
      "total_storage_overflow_mb",
      "total_downlink_shortfall_mb",
      "actual_data_volume_evidence_count",
      "total_actual_data_volume_mb",
      "total_data_volume_delta_mb",
      "actual_data_volume_under_delivered_activity_ids",
      "actual_data_volume_over_delivered_activity_ids",
      "actual_data_volume_exact_activity_ids",
      "total_battery_energy_consumed_wh",
      "total_battery_energy_generated_wh",
      "net_battery_energy_delta_wh",
      "peak_battery_overuse_wh",
      "projected_resources",
      "activity_resource_flow",
      "model_limits",
      "assumptions"
    ])
    |> expect_equal(
      path,
      summary,
      "schema_contract",
      "resource_projection_flow_summary.v1"
    )
    |> expect_equal(path, summary, "schema_version", 1)
    |> expect_equal(
      path,
      summary,
      "model",
      "artifact_only_selected_activity_resource_flow_summary"
    )
    |> expect_optional_type(path, summary, "source", :binary)
    |> expect_non_negative_integer(path, summary, "activity_count")
    |> expect_non_negative_integer(path, summary, "valid_activity_count")
    |> expect_non_negative_integer(path, summary, "invalid_activity_input_count")
    |> expect_type(path, summary, "invalid_activity_input_ids", :list)
    |> validate_optional_stable_id_list(path, summary, "invalid_activity_input_ids")
    |> expect_non_negative_integer(path, summary, "input_resource_summary_count")
    |> expect_non_negative_integer(path, summary, "valid_resource_summary_count")
    |> expect_non_negative_integer(
      path,
      summary,
      "invalid_resource_summary_input_count"
    )
    |> expect_type(path, summary, "invalid_resource_summary_input_ids", :list)
    |> validate_optional_stable_id_list(
      path,
      summary,
      "invalid_resource_summary_input_ids"
    )
    |> expect_non_negative_integer(path, summary, "projected_resource_count")
    |> expect_non_negative_integer(path, summary, "flow_row_count")
    |> expect_optional_non_negative_integer(path, summary, "ignored_activity_count")
    |> expect_optional_type(path, summary, "ignored_activity_reason_counts", :map)
    |> validate_non_negative_integer_count_map(
      path <> ".ignored_activity_reason_counts",
      Map.get(summary, "ignored_activity_reason_counts")
    )
    |> expect_optional_type(path, summary, "ignored_activity_ids", :list)
    |> validate_optional_stable_id_list(path, summary, "ignored_activity_ids")
    |> expect_optional_type(path, summary, "ignored_activity_ids_by_reason", :map)
    |> validate_optional_stable_id_array_map(
      path,
      summary,
      "ignored_activity_ids_by_reason"
    )
    |> expect_one_of(path, summary, "resource_flow_status", [
      "clear",
      "review_required"
    ])
    |> expect_one_of(path, summary, "resource_pressure_status", [
      "clear",
      "review_required"
    ])
    |> expect_non_negative_integer(path, summary, "resource_pressure_count")
    |> expect_type(path, summary, "resource_pressure_types", :list)
    |> validate_string_list_items(path, summary, "resource_pressure_types")
    |> expect_type(path, summary, "resource_pressure_spacecraft_ids", :list)
    |> validate_optional_stable_id_list(
      path,
      summary,
      "resource_pressure_spacecraft_ids"
    )
    |> expect_type(path, summary, "resource_pressure_spacecraft_ids_by_type", :map)
    |> validate_stable_id_array_map(
      path <> ".resource_pressure_spacecraft_ids_by_type",
      Map.get(summary, "resource_pressure_spacecraft_ids_by_type")
    )
    |> expect_type(path, summary, "resource_pressure_activity_ids_by_type", :map)
    |> validate_stable_id_array_map(
      path <> ".resource_pressure_activity_ids_by_type",
      Map.get(summary, "resource_pressure_activity_ids_by_type")
    )
    |> expect_optional_type(
      path,
      summary,
      "resource_pressure_ground_station_ids_by_type",
      :map
    )
    |> validate_optional_stable_id_array_map(
      path,
      summary,
      "resource_pressure_ground_station_ids_by_type"
    )
    |> expect_optional_type(
      path,
      summary,
      "resource_pressure_source_window_ids_by_type",
      :map
    )
    |> validate_optional_stable_id_array_map(
      path,
      summary,
      "resource_pressure_source_window_ids_by_type"
    )
    |> expect_optional_type(
      path,
      summary,
      "resource_pressure_station_calendar_entry_ids_by_type",
      :map
    )
    |> validate_optional_stable_id_array_map(
      path,
      summary,
      "resource_pressure_station_calendar_entry_ids_by_type"
    )
    |> expect_optional_type(
      path,
      summary,
      "resource_pressure_station_calendar_provider_ids_by_type",
      :map
    )
    |> validate_optional_stable_id_array_map(
      path,
      summary,
      "resource_pressure_station_calendar_provider_ids_by_type"
    )
    |> expect_optional_type(
      path,
      summary,
      "resource_pressure_station_calendar_provider_entry_ids_by_type",
      :map
    )
    |> validate_optional_stable_id_array_map(
      path,
      summary,
      "resource_pressure_station_calendar_provider_entry_ids_by_type"
    )
    |> expect_optional_type(
      path,
      summary,
      "resource_pressure_station_calendar_directions_by_type",
      :map
    )
    |> validate_string_list_map(
      path,
      summary,
      "resource_pressure_station_calendar_directions_by_type"
    )
    |> expect_optional_type(
      path,
      summary,
      "resource_pressure_capacity_fractions_by_type",
      :map
    )
    |> validate_number_array_map(
      path <> ".resource_pressure_capacity_fractions_by_type",
      Map.get(summary, "resource_pressure_capacity_fractions_by_type")
    )
    |> expect_number(path, summary, "total_storage_produced_mb")
    |> expect_number(path, summary, "total_planned_downlink_mb")
    |> expect_number(path, summary, "total_storage_limited_downlinked_mb")
    |> expect_number(path, summary, "total_unused_downlink_capacity_mb")
    |> expect_number(path, summary, "total_storage_overflow_mb")
    |> expect_number(path, summary, "total_downlink_shortfall_mb")
    |> expect_non_negative_integer(
      path,
      summary,
      "actual_data_volume_evidence_count"
    )
    |> expect_number(path, summary, "total_actual_data_volume_mb")
    |> expect_number(path, summary, "total_data_volume_delta_mb")
    |> expect_type(
      path,
      summary,
      "actual_data_volume_under_delivered_activity_ids",
      :list
    )
    |> validate_optional_stable_id_list(
      path,
      summary,
      "actual_data_volume_under_delivered_activity_ids"
    )
    |> expect_type(
      path,
      summary,
      "actual_data_volume_over_delivered_activity_ids",
      :list
    )
    |> validate_optional_stable_id_list(
      path,
      summary,
      "actual_data_volume_over_delivered_activity_ids"
    )
    |> expect_type(path, summary, "actual_data_volume_exact_activity_ids", :list)
    |> validate_optional_stable_id_list(
      path,
      summary,
      "actual_data_volume_exact_activity_ids"
    )
    |> expect_optional_one_of(path, summary, "latency_status", [
      "clear",
      "review_required"
    ])
    |> expect_optional_non_negative_integer(path, summary, "latency_evidence_count")
    |> expect_optional_non_negative_integer(path, summary, "latency_review_count")
    |> expect_optional_type(path, summary, "latency_review_activity_ids", :list)
    |> validate_optional_stable_id_list(path, summary, "latency_review_activity_ids")
    |> expect_optional_number(path, summary, "max_planned_latency_s")
    |> expect_optional_number(path, summary, "max_actual_latency_s")
    |> expect_optional_number(path, summary, "total_projected_storage_remaining_mb")
    |> expect_optional_number(path, summary, "minimum_projected_storage_remaining_mb")
    |> expect_optional_number(path, summary, "total_projected_downlink_remaining_mb")
    |> expect_optional_number(path, summary, "minimum_projected_downlink_remaining_mb")
    |> expect_number(path, summary, "total_battery_energy_consumed_wh")
    |> expect_number(path, summary, "total_battery_energy_generated_wh")
    |> expect_number(path, summary, "net_battery_energy_delta_wh")
    |> expect_number(path, summary, "peak_battery_overuse_wh")
    |> expect_type(path, summary, "projected_resources", :list)
    |> expect_type(path, summary, "activity_resource_flow", :list)
    |> expect_type(path, summary, "model_limits", :list)
    |> validate_string_list_items(path, summary, "model_limits")
    |> validate_optional_exact_model_limits(
      path,
      summary,
      model_limits,
      "must match resource projection model limits"
    )
    |> expect_type(path, summary, "assumptions", :map)
    |> subsystem_assumptions_validator.(path, summary)
    |> validate_rows(
      "#{path}.projected_resources",
      Map.get(summary, "projected_resources", []),
      fn acc, row_path, row ->
        projected_resource_validator.(acc, row_path, row)
      end
    )
    |> validate_rows(
      "#{path}.activity_resource_flow",
      Map.get(summary, "activity_resource_flow", []),
      fn acc, row_path, row ->
        flow_row_validator.(acc, row_path, row)
      end
    )
    |> counts_validator.(path, summary)
  end

  defp validate_optional_stable_id_array_map(issues, path, map, field) do
    issues
    |> expect_optional_type(path, map, field, :map)
    |> validate_stable_id_array_map(path <> ".#{field}", Map.get(map, field))
  end
end
