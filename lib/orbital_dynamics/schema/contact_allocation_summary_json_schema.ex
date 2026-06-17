defmodule OrbitalDynamics.Schema.ContactAllocationSummaryJsonSchema do
  @moduledoc false

  alias OrbitalDynamics.Schema.CommonJsonSchema

  @count_fields [
    "input_contact_count",
    "allocated_contact_count",
    "returned_allocated_contact_count",
    "policy_blocked_allocated_contact_count",
    "deferred_contact_count",
    "blocked_contact_count",
    "invalid_contact_input_count",
    "status_blocked_contact_count",
    "resource_blocked_contact_count",
    "duplicate_contact_id_count",
    "reduced_capacity_pack_group_count",
    "station_reservation_active_contact_count",
    "station_reservation_expired_contact_count",
    "station_reservation_missing_expiration_contact_count",
    "station_reservation_declared_expiration_contact_count",
    "review_row_count"
  ]

  @count_map_fields [
    "reduced_capacity_pack_status_counts",
    "allocation_status_counts",
    "effective_allocation_status_counts",
    "allocation_reason_counts",
    "capacity_pack_status_counts",
    "required_capacity_fraction_source_counts",
    "station_reservation_match_status_counts",
    "station_reservation_status_counts",
    "station_reserved_by_counts",
    "station_reservation_expiration_status_counts",
    "station_calendar_trust_boundary_status_counts",
    "calendar_entry_trust_boundary_status_counts",
    "resource_blocking_dimension_counts",
    "station_pressure_contact_counts_by_ground_station_id",
    "station_pressure_contact_counts_by_availability",
    "station_pressure_contact_counts_by_precedence_availability",
    "station_pressure_contact_counts_by_precedence_rank",
    "station_pressure_contact_counts_by_status"
  ]

  @number_fields [
    "capacity_pack_required_capacity_fraction",
    "capacity_pack_selected_required_capacity_fraction",
    "capacity_pack_deferred_required_capacity_fraction",
    "station_reservation_expiration_now_s",
    "earliest_station_reservation_expires_at_s"
  ]

  @number_map_fields [
    "capacity_pack_required_capacity_fraction_by_status",
    "capacity_pack_required_capacity_fraction_by_ground_station_id",
    "capacity_pack_selected_required_capacity_fraction_by_ground_station_id",
    "capacity_pack_deferred_required_capacity_fraction_by_ground_station_id"
  ]

  @stable_id_array_fields [
    "allocated_contact_ids",
    "returned_allocated_contact_ids",
    "deferred_contact_ids",
    "blocked_contact_ids",
    "policy_blocked_contact_ids",
    "invalid_contact_input_ids",
    "status_blocked_contact_ids",
    "resource_blocked_contact_ids",
    "station_reservation_ids",
    "reduced_capacity_packed_contact_ids",
    "reduced_capacity_deferred_contact_ids",
    "review_contact_ids"
  ]

  @stable_id_array_map_fields [
    "contact_ids_by_allocation_reason",
    "allocated_contact_ids_by_ground_station_id",
    "returned_allocated_contact_ids_by_ground_station_id",
    "deferred_contact_ids_by_ground_station_id",
    "blocked_contact_ids_by_ground_station_id",
    "policy_blocked_contact_ids_by_ground_station_id",
    "resource_blocked_contact_ids_by_blocking_dimension",
    "resource_blocked_contact_ids_by_spacecraft_id",
    "station_pressure_contact_ids_by_ground_station_id",
    "station_pressure_contact_ids_by_availability",
    "station_pressure_contact_ids_by_precedence_availability",
    "station_pressure_contact_ids_by_precedence_rank",
    "station_pressure_contact_ids_by_status",
    "station_reservation_contact_ids_by_match_status",
    "station_reservation_contact_ids_by_status",
    "station_reservation_contact_ids_by_reserved_by",
    "station_reservation_ids_by_match_status",
    "station_reservation_ids_by_status",
    "station_reservation_ids_by_reserved_by",
    "station_reservation_contact_ids_by_expiration_status",
    "station_reservation_ids_by_expiration_status",
    "capacity_pack_contact_ids_by_status",
    "capacity_pack_contact_ids_by_ground_station_id",
    "capacity_pack_selected_contact_ids_by_ground_station_id",
    "capacity_pack_deferred_contact_ids_by_ground_station_id",
    "required_capacity_fraction_contact_ids_by_source"
  ]

  def property("schema_contract", opts) do
    %{"type" => "string", "const" => Keyword.fetch!(opts, :schema_contract)}
  end

  def property("source_artifact_type", _opts) do
    %{"type" => "string", "enum" => ["contact_allocation_report.v1"]}
  end

  def property("model", _opts) do
    %{"type" => "string", "const" => "artifact_only_contact_allocation_summary"}
  end

  def property("source", _opts) do
    %{"type" => "string"}
  end

  def property("assumptions", opts) do
    Keyword.fetch!(opts, :assumptions_schema)
  end

  def property("model_limits", opts) do
    model_limits = Keyword.fetch!(opts, :model_limits)

    %{
      "type" => "array",
      "const" => model_limits,
      "items" => %{"type" => "string", "enum" => model_limits}
    }
  end

  def property(field, opts) when field in ["rows", "review_rows"] do
    %{"type" => "array", "items" => Keyword.fetch!(opts, :row_schema)}
  end

  def property("reduced_capacity_pack_groups", opts) do
    %{"type" => "array", "items" => Keyword.fetch!(opts, :capacity_pack_group_schema)}
  end

  def property(field, _opts) when field in @count_fields do
    %{"type" => "integer", "minimum" => 0}
  end

  def property(field, _opts) when field in @count_map_fields do
    CommonJsonSchema.non_negative_integer_count_map()
  end

  def property(field, _opts) when field in @number_fields do
    %{"type" => "number"}
  end

  def property(field, _opts) when field in @number_map_fields do
    CommonJsonSchema.non_negative_number_map()
  end

  def property("station_pressure_contact_ids_by_direction_and_ground_station_id", opts) do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> CommonJsonSchema.nested_stable_id_array_map()
  end

  def property(field, opts) when field in @stable_id_array_fields do
    stable_id_array(opts)
  end

  def property(field, opts) when field in @stable_id_array_map_fields do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> CommonJsonSchema.stable_id_array_map()
  end

  def property("station_reservation_expires_at_s", _opts) do
    %{"type" => "array", "items" => %{"type" => "number"}}
  end

  defp stable_id_array(opts) do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> CommonJsonSchema.stable_id_array()
  end
end
