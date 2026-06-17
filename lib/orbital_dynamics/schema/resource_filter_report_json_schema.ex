defmodule OrbitalDynamics.Schema.ResourceFilterReportJsonSchema do
  @moduledoc false

  alias OrbitalDynamics.Schema.CommonJsonSchema

  @stable_id_array_fields [
    "invalid_candidate_input_ids",
    "invalid_resource_summary_input_ids"
  ]

  @count_fields [
    "input_resource_summary_count",
    "valid_resource_summary_count",
    "invalid_resource_summary_input_count",
    "input_candidate_count",
    "kept_candidate_count",
    "suppressed_candidate_count",
    "invalid_candidate_input_count",
    "duplicate_suppressed_candidate_row_count",
    "duplicate_suppressed_candidate_id_count"
  ]

  @count_map_fields [
    "resource_source_quality_counts",
    "resource_trust_boundary_status_counts",
    "suppressed_resource_source_quality_counts",
    "suppressed_resource_trust_boundary_status_counts"
  ]

  @stable_id_array_map_fields [
    "suppressed_candidate_ids_by_resource_source_quality",
    "suppressed_candidate_ids_by_resource_trust_boundary_status"
  ]

  def property("model", _opts) do
    %{"type" => "string", "const" => "resource_summary_availability_and_margin_filter"}
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

  def property("suppressed_candidates", opts) do
    %{"type" => "array", "items" => Keyword.fetch!(opts, :suppressed_candidate_schema)}
  end

  def property(field, opts) when field in @stable_id_array_fields do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> CommonJsonSchema.stable_id_array()
  end

  def property(field, _opts) when field in @count_fields do
    %{"type" => "integer", "minimum" => 0}
  end

  def property(field, _opts) when field in @count_map_fields do
    CommonJsonSchema.non_negative_integer_count_map()
  end

  def property(field, opts) when field in @stable_id_array_map_fields do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> CommonJsonSchema.stable_id_array_map()
  end
end
