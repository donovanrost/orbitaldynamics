defmodule OrbitalDynamics.Schema.ResourceProjectionFlowSummaryJsonSchema do
  @moduledoc false

  alias OrbitalDynamics.Schema.CommonJsonSchema

  @status_fields [
    "resource_flow_status",
    "resource_pressure_status",
    "latency_status"
  ]

  @count_fields [
    "activity_count",
    "valid_activity_count",
    "invalid_activity_input_count",
    "input_resource_summary_count",
    "valid_resource_summary_count",
    "invalid_resource_summary_input_count",
    "projected_resource_count",
    "flow_row_count",
    "resource_pressure_count",
    "actual_data_volume_evidence_count",
    "latency_evidence_count",
    "latency_review_count",
    "ignored_activity_count"
  ]

  @count_map_fields [
    "ignored_activity_reason_counts"
  ]

  @stable_id_array_fields [
    "invalid_activity_input_ids",
    "invalid_resource_summary_input_ids",
    "resource_pressure_types",
    "resource_pressure_spacecraft_ids",
    "actual_data_volume_under_delivered_activity_ids",
    "actual_data_volume_over_delivered_activity_ids",
    "actual_data_volume_exact_activity_ids",
    "latency_review_activity_ids",
    "ignored_activity_ids"
  ]

  @stable_id_array_map_fields [
    "resource_pressure_spacecraft_ids_by_type",
    "resource_pressure_activity_ids_by_type",
    "resource_pressure_ground_station_ids_by_type",
    "resource_pressure_source_window_ids_by_type",
    "resource_pressure_station_calendar_entry_ids_by_type",
    "resource_pressure_station_calendar_provider_ids_by_type",
    "resource_pressure_station_calendar_provider_entry_ids_by_type",
    "ignored_activity_ids_by_reason"
  ]

  @number_fields [
    "total_storage_produced_mb",
    "total_planned_downlink_mb",
    "total_storage_limited_downlinked_mb",
    "total_unused_downlink_capacity_mb",
    "total_storage_overflow_mb",
    "total_downlink_shortfall_mb",
    "total_actual_data_volume_mb",
    "total_data_volume_delta_mb",
    "total_projected_storage_remaining_mb",
    "minimum_projected_storage_remaining_mb",
    "total_projected_downlink_remaining_mb",
    "minimum_projected_downlink_remaining_mb",
    "total_battery_energy_consumed_wh",
    "total_battery_energy_generated_wh",
    "net_battery_energy_delta_wh",
    "peak_battery_overuse_wh",
    "max_planned_latency_s",
    "max_actual_latency_s"
  ]

  def property("model", _opts) do
    %{"type" => "string", "const" => "artifact_only_selected_activity_resource_flow_summary"}
  end

  def property("source", _opts) do
    %{"type" => "string"}
  end

  def property(field, _opts) when field in @status_fields do
    %{"type" => "string", "enum" => ["clear", "review_required"]}
  end

  def property(field, _opts) when field in @count_fields do
    %{"type" => "integer", "minimum" => 0}
  end

  def property(field, _opts) when field in @count_map_fields do
    CommonJsonSchema.non_negative_integer_count_map()
  end

  def property(field, opts) when field in @stable_id_array_fields do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> CommonJsonSchema.stable_id_array()
  end

  def property(field, opts) when field in @stable_id_array_map_fields do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> CommonJsonSchema.stable_id_array_map()
  end

  def property("resource_pressure_station_calendar_directions_by_type", _opts) do
    CommonJsonSchema.string_list_map()
  end

  def property("resource_pressure_capacity_fractions_by_type", _opts) do
    CommonJsonSchema.number_array_map()
  end

  def property(field, _opts) when field in @number_fields do
    %{"type" => "number"}
  end

  def property("projected_resources", _opts) do
    %{
      "type" => "array",
      "items" => %{"type" => "object", "additionalProperties" => true}
    }
  end

  def property("activity_resource_flow", opts) do
    %{
      "type" => "array",
      "items" => Keyword.fetch!(opts, :activity_resource_flow_row_schema)
    }
  end

  def property("model_limits", opts) do
    model_limits = Keyword.fetch!(opts, :model_limits)

    %{
      "type" => "array",
      "const" => model_limits,
      "items" => %{"type" => "string", "enum" => model_limits}
    }
  end

  def property("assumptions", opts) do
    Keyword.fetch!(opts, :assumptions_schema)
  end
end
