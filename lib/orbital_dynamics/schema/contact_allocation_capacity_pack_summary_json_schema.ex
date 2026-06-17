defmodule OrbitalDynamics.Schema.ContactAllocationCapacityPackSummaryJsonSchema do
  @moduledoc false

  alias OrbitalDynamics.Schema.CommonJsonSchema

  @count_fields [
    "input_contact_count",
    "capacity_pack_contact_count",
    "reduced_capacity_pack_group_count"
  ]

  @count_map_fields [
    "reduced_capacity_pack_status_counts",
    "capacity_pack_status_counts",
    "required_capacity_fraction_source_counts"
  ]

  @stable_id_array_map_fields [
    "capacity_pack_contact_ids_by_status",
    "capacity_pack_contact_ids_by_ground_station_id",
    "capacity_pack_selected_contact_ids_by_ground_station_id",
    "capacity_pack_deferred_contact_ids_by_ground_station_id",
    "capacity_pack_contact_ids_by_direction",
    "capacity_pack_selected_contact_ids_by_direction",
    "capacity_pack_deferred_contact_ids_by_direction",
    "required_capacity_fraction_contact_ids_by_source",
    "capacity_pack_group_ids_by_status"
  ]

  @stable_id_array_fields [
    "reduced_capacity_packed_contact_ids",
    "reduced_capacity_deferred_contact_ids",
    "capacity_pack_group_ids"
  ]

  @number_fields [
    "capacity_pack_required_capacity_fraction",
    "capacity_pack_selected_required_capacity_fraction",
    "capacity_pack_deferred_required_capacity_fraction"
  ]

  @number_map_fields [
    "capacity_pack_required_capacity_fraction_by_status",
    "capacity_pack_required_capacity_fraction_by_ground_station_id",
    "capacity_pack_selected_required_capacity_fraction_by_ground_station_id",
    "capacity_pack_deferred_required_capacity_fraction_by_ground_station_id",
    "capacity_pack_required_capacity_fraction_by_direction",
    "capacity_pack_selected_required_capacity_fraction_by_direction",
    "capacity_pack_deferred_required_capacity_fraction_by_direction"
  ]

  def property("schema_contract", opts) do
    %{"type" => "string", "const" => Keyword.fetch!(opts, :schema_contract)}
  end

  def property("model", _opts) do
    %{"type" => "string", "const" => "artifact_only_contact_allocation_capacity_pack_summary"}
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

  def property("source_artifact_type", _opts) do
    %{"type" => "string", "enum" => ["contact_allocation_report.v1"]}
  end

  def property("source", _opts) do
    %{"type" => "string"}
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

  def property("capacity_pack_review_status", _opts) do
    %{"type" => "string", "enum" => ["clear", "review_required"]}
  end

  def property(field, _opts) when field in @count_map_fields do
    CommonJsonSchema.non_negative_integer_count_map()
  end

  def property(field, opts) when field in @stable_id_array_map_fields do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> CommonJsonSchema.stable_id_array_map()
  end

  def property(field, opts) when field in @stable_id_array_fields do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> CommonJsonSchema.stable_id_array()
  end

  def property(field, _opts) when field in @number_fields do
    %{"type" => "number", "minimum" => 0.0}
  end

  def property(field, _opts) when field in @number_map_fields do
    CommonJsonSchema.non_negative_number_map()
  end
end
