defmodule OrbitalDynamics.Schema.ResourceProjectionReportJsonSchema do
  @moduledoc false

  alias OrbitalDynamics.Schema.CommonJsonSchema

  @stable_id_array_fields [
    "invalid_resource_summary_input_ids",
    "invalid_activity_input_ids",
    "resource_pressure_spacecraft_ids",
    "resource_pressure_types"
  ]

  @count_fields [
    "input_resource_summary_count",
    "activity_count",
    "valid_resource_summary_count",
    "invalid_resource_summary_input_count",
    "valid_activity_count",
    "invalid_activity_input_count",
    "resource_pressure_count"
  ]

  @stable_id_array_map_fields [
    "resource_pressure_spacecraft_ids_by_type",
    "resource_pressure_activity_ids_by_type",
    "resource_spacecraft_ids_by_source_quality",
    "resource_spacecraft_ids_by_trust_boundary_status"
  ]

  @count_map_fields [
    "resource_source_quality_counts",
    "resource_trust_boundary_status_counts"
  ]

  def property("model", opts) do
    %{"type" => "string", "enum" => Keyword.fetch!(opts, :models)}
  end

  def property("source", _opts) do
    %{"type" => "string"}
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

  def property("projected_resources", opts) do
    %{"type" => "array", "items" => Keyword.fetch!(opts, :resource_projection_row_schema)}
  end

  def property(field, opts) when field in @stable_id_array_fields do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> CommonJsonSchema.stable_id_array()
  end

  def property(field, _opts) when field in @count_fields do
    %{"type" => "integer", "minimum" => 0}
  end

  def property(field, opts) when field in @stable_id_array_map_fields do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> CommonJsonSchema.stable_id_array_map()
  end

  def property(field, _opts) when field in @count_map_fields do
    CommonJsonSchema.non_negative_integer_count_map()
  end
end
