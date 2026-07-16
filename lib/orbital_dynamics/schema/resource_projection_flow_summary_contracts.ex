defmodule OrbitalDynamics.Schema.ResourceProjectionFlowSummaryContracts do
  @moduledoc false

  def validate(issues, path, summary, model_limits, callbacks) when is_list(callbacks) do
    issues
    |> require_fields(callbacks, path, summary, [
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
      callbacks,
      path,
      summary,
      "schema_contract",
      "resource_projection_flow_summary.v1"
    )
    |> expect_equal(callbacks, path, summary, "schema_version", 1)
    |> expect_equal(
      callbacks,
      path,
      summary,
      "model",
      "artifact_only_selected_activity_resource_flow_summary"
    )
    |> expect_optional_type(callbacks, path, summary, "source", :binary)
    |> expect_non_negative_integer(callbacks, path, summary, "activity_count")
    |> expect_non_negative_integer(callbacks, path, summary, "valid_activity_count")
    |> expect_non_negative_integer(callbacks, path, summary, "invalid_activity_input_count")
    |> expect_type(callbacks, path, summary, "invalid_activity_input_ids", :list)
    |> validate_optional_stable_id_list(callbacks, path, summary, "invalid_activity_input_ids")
    |> expect_non_negative_integer(callbacks, path, summary, "input_resource_summary_count")
    |> expect_non_negative_integer(callbacks, path, summary, "valid_resource_summary_count")
    |> expect_non_negative_integer(
      callbacks,
      path,
      summary,
      "invalid_resource_summary_input_count"
    )
    |> expect_type(callbacks, path, summary, "invalid_resource_summary_input_ids", :list)
    |> validate_optional_stable_id_list(
      callbacks,
      path,
      summary,
      "invalid_resource_summary_input_ids"
    )
    |> expect_non_negative_integer(callbacks, path, summary, "projected_resource_count")
    |> expect_non_negative_integer(callbacks, path, summary, "flow_row_count")
    |> expect_optional_non_negative_integer(callbacks, path, summary, "ignored_activity_count")
    |> expect_optional_type(callbacks, path, summary, "ignored_activity_reason_counts", :map)
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".ignored_activity_reason_counts",
      Map.get(summary, "ignored_activity_reason_counts")
    )
    |> expect_optional_type(callbacks, path, summary, "ignored_activity_ids", :list)
    |> validate_optional_stable_id_list(callbacks, path, summary, "ignored_activity_ids")
    |> expect_optional_type(callbacks, path, summary, "ignored_activity_ids_by_reason", :map)
    |> validate_optional_stable_id_array_map(
      callbacks,
      path,
      summary,
      "ignored_activity_ids_by_reason"
    )
    |> expect_one_of(callbacks, path, summary, "resource_flow_status", [
      "clear",
      "review_required"
    ])
    |> expect_one_of(callbacks, path, summary, "resource_pressure_status", [
      "clear",
      "review_required"
    ])
    |> expect_non_negative_integer(callbacks, path, summary, "resource_pressure_count")
    |> expect_type(callbacks, path, summary, "resource_pressure_types", :list)
    |> validate_string_list_items(callbacks, path, summary, "resource_pressure_types")
    |> expect_type(callbacks, path, summary, "resource_pressure_spacecraft_ids", :list)
    |> validate_optional_stable_id_list(
      callbacks,
      path,
      summary,
      "resource_pressure_spacecraft_ids"
    )
    |> expect_type(callbacks, path, summary, "resource_pressure_spacecraft_ids_by_type", :map)
    |> validate_stable_id_array_map(
      callbacks,
      path <> ".resource_pressure_spacecraft_ids_by_type",
      Map.get(summary, "resource_pressure_spacecraft_ids_by_type")
    )
    |> expect_type(callbacks, path, summary, "resource_pressure_activity_ids_by_type", :map)
    |> validate_stable_id_array_map(
      callbacks,
      path <> ".resource_pressure_activity_ids_by_type",
      Map.get(summary, "resource_pressure_activity_ids_by_type")
    )
    |> expect_optional_type(
      callbacks,
      path,
      summary,
      "resource_pressure_ground_station_ids_by_type",
      :map
    )
    |> validate_optional_stable_id_array_map(
      callbacks,
      path,
      summary,
      "resource_pressure_ground_station_ids_by_type"
    )
    |> expect_optional_type(
      callbacks,
      path,
      summary,
      "resource_pressure_source_window_ids_by_type",
      :map
    )
    |> validate_optional_stable_id_array_map(
      callbacks,
      path,
      summary,
      "resource_pressure_source_window_ids_by_type"
    )
    |> expect_optional_type(
      callbacks,
      path,
      summary,
      "resource_pressure_station_calendar_entry_ids_by_type",
      :map
    )
    |> validate_optional_stable_id_array_map(
      callbacks,
      path,
      summary,
      "resource_pressure_station_calendar_entry_ids_by_type"
    )
    |> expect_optional_type(
      callbacks,
      path,
      summary,
      "resource_pressure_station_calendar_provider_ids_by_type",
      :map
    )
    |> validate_optional_stable_id_array_map(
      callbacks,
      path,
      summary,
      "resource_pressure_station_calendar_provider_ids_by_type"
    )
    |> expect_optional_type(
      callbacks,
      path,
      summary,
      "resource_pressure_station_calendar_provider_entry_ids_by_type",
      :map
    )
    |> validate_optional_stable_id_array_map(
      callbacks,
      path,
      summary,
      "resource_pressure_station_calendar_provider_entry_ids_by_type"
    )
    |> expect_optional_type(
      callbacks,
      path,
      summary,
      "resource_pressure_station_calendar_directions_by_type",
      :map
    )
    |> validate_string_list_map(
      callbacks,
      path,
      summary,
      "resource_pressure_station_calendar_directions_by_type"
    )
    |> expect_optional_type(
      callbacks,
      path,
      summary,
      "resource_pressure_capacity_fractions_by_type",
      :map
    )
    |> validate_number_array_map(
      callbacks,
      path <> ".resource_pressure_capacity_fractions_by_type",
      Map.get(summary, "resource_pressure_capacity_fractions_by_type")
    )
    |> expect_number(callbacks, path, summary, "total_storage_produced_mb")
    |> expect_number(callbacks, path, summary, "total_planned_downlink_mb")
    |> expect_number(callbacks, path, summary, "total_storage_limited_downlinked_mb")
    |> expect_number(callbacks, path, summary, "total_unused_downlink_capacity_mb")
    |> expect_number(callbacks, path, summary, "total_storage_overflow_mb")
    |> expect_number(callbacks, path, summary, "total_downlink_shortfall_mb")
    |> expect_non_negative_integer(
      callbacks,
      path,
      summary,
      "actual_data_volume_evidence_count"
    )
    |> expect_number(callbacks, path, summary, "total_actual_data_volume_mb")
    |> expect_number(callbacks, path, summary, "total_data_volume_delta_mb")
    |> expect_type(
      callbacks,
      path,
      summary,
      "actual_data_volume_under_delivered_activity_ids",
      :list
    )
    |> validate_optional_stable_id_list(
      callbacks,
      path,
      summary,
      "actual_data_volume_under_delivered_activity_ids"
    )
    |> expect_type(
      callbacks,
      path,
      summary,
      "actual_data_volume_over_delivered_activity_ids",
      :list
    )
    |> validate_optional_stable_id_list(
      callbacks,
      path,
      summary,
      "actual_data_volume_over_delivered_activity_ids"
    )
    |> expect_type(callbacks, path, summary, "actual_data_volume_exact_activity_ids", :list)
    |> validate_optional_stable_id_list(
      callbacks,
      path,
      summary,
      "actual_data_volume_exact_activity_ids"
    )
    |> expect_optional_one_of(callbacks, path, summary, "latency_status", [
      "clear",
      "review_required"
    ])
    |> expect_optional_non_negative_integer(callbacks, path, summary, "latency_evidence_count")
    |> expect_optional_non_negative_integer(callbacks, path, summary, "latency_review_count")
    |> expect_optional_type(callbacks, path, summary, "latency_review_activity_ids", :list)
    |> validate_optional_stable_id_list(callbacks, path, summary, "latency_review_activity_ids")
    |> expect_optional_number(callbacks, path, summary, "max_planned_latency_s")
    |> expect_optional_number(callbacks, path, summary, "max_actual_latency_s")
    |> expect_optional_number(callbacks, path, summary, "total_projected_storage_remaining_mb")
    |> expect_optional_number(callbacks, path, summary, "minimum_projected_storage_remaining_mb")
    |> expect_optional_number(callbacks, path, summary, "total_projected_downlink_remaining_mb")
    |> expect_optional_number(callbacks, path, summary, "minimum_projected_downlink_remaining_mb")
    |> expect_number(callbacks, path, summary, "total_battery_energy_consumed_wh")
    |> expect_number(callbacks, path, summary, "total_battery_energy_generated_wh")
    |> expect_number(callbacks, path, summary, "net_battery_energy_delta_wh")
    |> expect_number(callbacks, path, summary, "peak_battery_overuse_wh")
    |> expect_type(callbacks, path, summary, "projected_resources", :list)
    |> expect_type(callbacks, path, summary, "activity_resource_flow", :list)
    |> expect_type(callbacks, path, summary, "model_limits", :list)
    |> validate_string_list_items(callbacks, path, summary, "model_limits")
    |> validate_optional_exact_model_limits(
      callbacks,
      path,
      summary,
      model_limits,
      "must match resource projection model limits"
    )
    |> expect_type(callbacks, path, summary, "assumptions", :map)
    |> validate_resource_projection_subsystem_model_assumptions(callbacks, path, summary)
    |> validate_rows(
      callbacks,
      "#{path}.projected_resources",
      Map.get(summary, "projected_resources", []),
      fn acc, row_path, row ->
        validate_resource_projection_flow_summary_projected_resource(
          callbacks,
          acc,
          row_path,
          row
        )
      end
    )
    |> validate_rows(
      callbacks,
      "#{path}.activity_resource_flow",
      Map.get(summary, "activity_resource_flow", []),
      fn acc, row_path, row ->
        validate_resource_projection_flow_row(callbacks, acc, row_path, row)
      end
    )
    |> validate_resource_projection_flow_summary_counts(callbacks, path, summary)
  end

  defp require_callback(callbacks, name) do
    case Keyword.fetch(callbacks, name) do
      {:ok, callback} -> callback
      :error -> raise ArgumentError, "missing callback #{inspect(name)}"
    end
  end

  defp require_fields(issues, callbacks, path, map, fields),
    do: apply(require_callback(callbacks, :require_fields), [issues, path, map, fields])

  defp expect_equal(issues, callbacks, path, map, field, expected),
    do: apply(require_callback(callbacks, :expect_equal), [issues, path, map, field, expected])

  defp expect_optional_type(issues, callbacks, path, map, field, type),
    do:
      apply(require_callback(callbacks, :expect_optional_type), [issues, path, map, field, type])

  defp expect_non_negative_integer(issues, callbacks, path, map, field),
    do:
      apply(require_callback(callbacks, :expect_non_negative_integer), [
        issues,
        path,
        map,
        field
      ])

  defp expect_type(issues, callbacks, path, map, field, type),
    do: apply(require_callback(callbacks, :expect_type), [issues, path, map, field, type])

  defp validate_optional_stable_id_list(issues, callbacks, path, map, field),
    do:
      apply(require_callback(callbacks, :validate_optional_stable_id_list), [
        issues,
        path,
        map,
        field
      ])

  defp expect_optional_non_negative_integer(issues, callbacks, path, map, field),
    do:
      apply(require_callback(callbacks, :expect_optional_non_negative_integer), [
        issues,
        path,
        map,
        field
      ])

  defp validate_non_negative_integer_count_map(issues, callbacks, path, values),
    do:
      apply(require_callback(callbacks, :validate_non_negative_integer_count_map), [
        issues,
        path,
        values
      ])

  defp validate_optional_stable_id_array_map(issues, callbacks, path, map, field),
    do:
      apply(require_callback(callbacks, :validate_optional_stable_id_array_map), [
        issues,
        path,
        map,
        field
      ])

  defp expect_one_of(issues, callbacks, path, map, field, allowed),
    do: apply(require_callback(callbacks, :expect_one_of), [issues, path, map, field, allowed])

  defp validate_string_list_items(issues, callbacks, path, map, field),
    do:
      apply(require_callback(callbacks, :validate_string_list_items), [issues, path, map, field])

  defp validate_stable_id_array_map(issues, callbacks, path, values),
    do: apply(require_callback(callbacks, :validate_stable_id_array_map), [issues, path, values])

  defp validate_string_list_map(issues, callbacks, path, map, field),
    do: apply(require_callback(callbacks, :validate_string_list_map), [issues, path, map, field])

  defp validate_number_array_map(issues, callbacks, path, values),
    do: apply(require_callback(callbacks, :validate_number_array_map), [issues, path, values])

  defp expect_number(issues, callbacks, path, map, field),
    do: apply(require_callback(callbacks, :expect_number), [issues, path, map, field])

  defp expect_optional_one_of(issues, callbacks, path, map, field, allowed),
    do:
      apply(require_callback(callbacks, :expect_optional_one_of), [
        issues,
        path,
        map,
        field,
        allowed
      ])

  defp expect_optional_number(issues, callbacks, path, map, field),
    do: apply(require_callback(callbacks, :expect_optional_number), [issues, path, map, field])

  defp validate_optional_exact_model_limits(issues, callbacks, path, artifact, expected, message),
    do:
      apply(require_callback(callbacks, :validate_optional_exact_model_limits), [
        issues,
        path,
        artifact,
        expected,
        message
      ])

  defp validate_resource_projection_subsystem_model_assumptions(
         issues,
         callbacks,
         path,
         artifact
       ),
       do:
         apply(
           require_callback(callbacks, :validate_resource_projection_subsystem_model_assumptions),
           [issues, path, artifact]
         )

  defp validate_rows(issues, callbacks, path, rows, validator),
    do: apply(require_callback(callbacks, :validate_rows), [issues, path, rows, validator])

  defp validate_resource_projection_flow_summary_projected_resource(callbacks, issues, path, row),
    do:
      apply(
        require_callback(
          callbacks,
          :validate_resource_projection_flow_summary_projected_resource
        ),
        [issues, path, row]
      )

  defp validate_resource_projection_flow_row(callbacks, issues, path, row),
    do:
      apply(require_callback(callbacks, :validate_resource_projection_flow_row), [
        issues,
        path,
        row
      ])

  defp validate_resource_projection_flow_summary_counts(issues, callbacks, path, summary),
    do:
      apply(require_callback(callbacks, :validate_resource_projection_flow_summary_counts), [
        issues,
        path,
        summary
      ])
end
