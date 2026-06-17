defmodule OrbitalDynamics.Schema.ResourceFilterSummaryJsonSchema do
  @moduledoc false

  alias OrbitalDynamics.Schema.CommonJsonSchema

  @count_fields [
    "input_candidate_count",
    "kept_candidate_count",
    "suppressed_candidate_count",
    "invalid_candidate_input_count",
    "invalid_resource_summary_input_count",
    "duplicate_suppressed_candidate_id_count",
    "duplicate_suppressed_candidate_row_count"
  ]

  @count_map_fields [
    "suppressed_reason_counts",
    "resource_blocking_dimension_counts",
    "suppressed_resource_source_quality_counts",
    "suppressed_resource_trust_boundary_status_counts"
  ]

  @stable_id_array_fields [
    "suppressed_candidate_ids",
    "invalid_candidate_input_ids",
    "invalid_resource_summary_input_ids"
  ]

  @stable_id_array_map_fields [
    "suppressed_candidate_ids_by_reason",
    "suppressed_candidate_ids_by_resource_blocking_dimension",
    "suppressed_candidate_ids_by_spacecraft_id",
    "suppressed_candidate_ids_by_scenario_id",
    "suppressed_candidate_ids_by_resource_source_quality",
    "suppressed_candidate_ids_by_resource_trust_boundary_status"
  ]

  def property("schema_contract", opts) do
    %{"type" => "string", "const" => Keyword.fetch!(opts, :schema_contract)}
  end

  def property("model", _opts) do
    %{"type" => "string", "const" => "artifact_only_resource_filter_summary"}
  end

  def property("source_artifact_type", opts) do
    %{"type" => "string", "const" => Keyword.fetch!(opts, :source_artifact_type)}
  end

  def property("model_limits", opts) do
    model_limits = Keyword.fetch!(opts, :model_limits)

    %{
      "type" => "array",
      "const" => model_limits,
      "items" => %{"type" => "string", "enum" => model_limits}
    }
  end

  def property("suppression_review_status", _opts) do
    %{"type" => "string", "enum" => ["clear", "review_required"]}
  end

  def property("assumptions", opts) do
    Keyword.fetch!(opts, :assumptions_schema)
  end

  def property("review_rows", opts) do
    %{"type" => "array", "items" => Keyword.fetch!(opts, :suppressed_candidate_schema)}
  end

  def property("invalid_resource_summary_inputs", _opts) do
    %{
      "type" => "array",
      "items" => %{"type" => "object", "additionalProperties" => true}
    }
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
end
