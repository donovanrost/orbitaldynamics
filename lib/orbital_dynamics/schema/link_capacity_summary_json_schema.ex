defmodule OrbitalDynamics.Schema.LinkCapacitySummaryJsonSchema do
  @moduledoc false

  @summary "link_capacity_summary.v1"
  @report "link_capacity_report.v1"

  @status_string_fields [
    "downlink_requirement_status",
    "actual_downlink_requirement_status",
    "selection_utilization_status"
  ]

  @integer_fields [
    "station_count",
    "contact_count",
    "effective_contact_count",
    "ignored_contact_count",
    "selected_contact_count",
    "ignored_selected_contact_count",
    "required_downlink_contact_count",
    "actual_throughput_contact_count",
    "actual_completion_contact_count",
    "unmatched_actual_throughput_contact_count",
    "ambiguous_actual_throughput_contact_count",
    "unmatched_actual_completion_contact_count",
    "ambiguous_actual_completion_contact_count",
    "invalid_contact_input_count",
    "invalid_selected_contact_input_count",
    "invalid_policy_required_downlink_station_count"
  ]

  @number_fields [
    "selected_downlink_shortfall_mb",
    "actual_downlink_shortfall_mb",
    "capacity_adjusted_throughput_mb",
    "selected_capacity_adjusted_throughput_mb",
    "unused_capacity_adjusted_throughput_mb"
  ]

  @count_map_fields [
    "ignored_contact_reason_counts",
    "ignored_selected_contact_reason_counts",
    "station_reservation_match_status_counts"
  ]

  @stable_id_array_fields [
    "station_calendar_entry_ids",
    "station_calendar_provider_ids",
    "station_calendar_provider_entry_ids",
    "station_reservation_ids",
    "contact_ids",
    "selected_contact_ids",
    "ignored_contact_ids",
    "ignored_selected_contact_ids",
    "required_downlink_contact_ids",
    "actual_throughput_contact_ids",
    "actual_completion_contact_ids",
    "unmatched_actual_throughput_contact_ids",
    "ambiguous_actual_throughput_contact_ids",
    "unmatched_actual_completion_contact_ids",
    "ambiguous_actual_completion_contact_ids",
    "ambiguous_selected_contact_ids",
    "unmatched_selected_contact_ids",
    "invalid_contact_input_ids",
    "invalid_selected_contact_input_ids",
    "ground_station_ids",
    "shortfall_ground_station_ids",
    "actual_shortfall_ground_station_ids"
  ]

  @string_array_fields [
    "invalid_policy_required_downlink_station_ids",
    "station_reserved_bys",
    "station_reservation_statuses"
  ]

  @number_array_fields ["station_reservation_expires_at_s"]

  @numeric_map_fields [
    "selected_downlink_shortfall_mb_by_ground_station_id",
    "actual_downlink_shortfall_mb_by_ground_station_id",
    "capacity_adjusted_throughput_mb_by_ground_station_id",
    "selected_capacity_adjusted_throughput_mb_by_ground_station_id",
    "unused_capacity_adjusted_throughput_mb_by_ground_station_id"
  ]

  @stable_id_array_map_fields [
    "station_calendar_entry_ids_by_ground_station_id",
    "station_calendar_provider_ids_by_ground_station_id",
    "station_calendar_provider_entry_ids_by_ground_station_id",
    "station_reservation_ids_by_ground_station_id",
    "ignored_contact_ids_by_ground_station_id",
    "selected_contact_ids_by_ground_station_id",
    "required_downlink_contact_ids_by_ground_station_id",
    "actual_throughput_contact_ids_by_ground_station_id",
    "actual_completion_contact_ids_by_ground_station_id",
    "unmatched_actual_throughput_contact_ids_by_ground_station_id",
    "ambiguous_actual_throughput_contact_ids_by_ground_station_id",
    "unmatched_actual_completion_contact_ids_by_ground_station_id",
    "ambiguous_actual_completion_contact_ids_by_ground_station_id",
    "ground_station_ids_by_station_availability",
    "ground_station_ids_by_reservation_match_status",
    "ground_station_ids_by_reservation_status",
    "ground_station_ids_by_reserved_by"
  ]

  def property("schema_contract", _opts) do
    %{"type" => "string", "const" => @summary}
  end

  def property("source_artifact_type", _opts) do
    %{"type" => "string", "enum" => [@report]}
  end

  def property("model", _opts) do
    %{"type" => "string", "const" => "artifact_only_link_capacity_summary"}
  end

  def property("model_limits", opts) do
    model_limits = Keyword.fetch!(opts, :model_limits)

    %{
      "type" => "array",
      "const" => model_limits,
      "items" => %{"type" => "string", "enum" => model_limits}
    }
  end

  def property("source", _opts) do
    %{"type" => "string"}
  end

  def property("assumptions", opts) do
    Keyword.fetch!(opts, :assumptions_schema)
  end

  def property(field, _opts) when field in @status_string_fields do
    %{"type" => "string"}
  end

  def property(field, _opts) when field in @integer_fields do
    %{"type" => "integer", "minimum" => 0}
  end

  def property(field, _opts) when field in @number_fields do
    %{"type" => "number"}
  end

  def property(field, opts) when field in @count_map_fields do
    Keyword.fetch!(opts, :count_map_schema)
  end

  def property(field, opts) when field in @stable_id_array_fields do
    Keyword.fetch!(opts, :stable_id_array_schema)
  end

  def property(field, opts) when field in @string_array_fields do
    Keyword.fetch!(opts, :string_array_schema)
  end

  def property(field, opts) when field in @number_array_fields do
    Keyword.fetch!(opts, :number_array_schema)
  end

  def property(field, opts) when field in @numeric_map_fields do
    Keyword.fetch!(opts, :numeric_map_schema)
  end

  def property(field, opts) when field in @stable_id_array_map_fields do
    Keyword.fetch!(opts, :stable_id_array_map_schema)
  end
end
