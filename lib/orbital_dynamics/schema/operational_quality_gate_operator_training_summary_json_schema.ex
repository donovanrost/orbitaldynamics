defmodule OrbitalDynamics.Schema.OperationalQualityGateOperatorTrainingSummaryJsonSchema do
  @moduledoc false

  alias OrbitalDynamics.Schema.CommonJsonSchema

  @stable_id_fields [
    "source_artifact_id",
    "source_quality_gate_report_id",
    "source_readiness_report_id"
  ]

  @count_fields [
    "operator_training_row_count",
    "operator_training_requirement_count"
  ]

  @stable_id_array_map_fields [
    "quality_gate_row_ids_by_status",
    "quality_gate_row_ids_by_classification",
    "quality_gate_ids_by_status",
    "quality_gate_ids_by_classification"
  ]

  @string_array_fields [
    "operator_training_requirement_ids",
    "required_operator_roles",
    "required_training_ids",
    "required_certification_ids",
    "required_qualification_ids",
    "review_required_quality_gate_row_ids",
    "blocked_quality_gate_row_ids",
    "review_only_quality_gate_row_ids",
    "operator_training_gate_ids"
  ]

  def property_field?(field)
      when field in [
             "schema_contract",
             "source",
             "model",
             "model_limits",
             "operator_training_requirement_counts",
             "operator_training_review_required",
             "assumptions"
           ],
      do: true

  def property_field?(field) when field in @stable_id_fields, do: true
  def property_field?(field) when field in @count_fields, do: true
  def property_field?(field) when field in @stable_id_array_map_fields, do: true
  def property_field?(field) when field in @string_array_fields, do: true
  def property_field?(_field), do: false

  def property_opts("model_limits", deps) do
    [model_limits: fetch_dep!(deps, :model_limits)]
  end

  def property_opts(field, deps)
      when field in @stable_id_fields or field in @stable_id_array_map_fields do
    [stable_id_pattern: fetch_dep!(deps, :stable_id_pattern)]
  end

  def property_opts(_field, _deps), do: []

  def property_fun_from_context(deps) when is_list(deps) do
    fn field -> property_from_context(field, deps) end
  end

  def property_from_context(field, deps) when is_list(deps) do
    property(field, property_opts(field, deps))
  end

  def property("schema_contract", _opts) do
    %{"type" => "string", "const" => "operational_quality_gate_operator_training_summary.v1"}
  end

  def property("source", _opts) do
    %{"type" => "string", "enum" => ["quality_gate_report.v1"]}
  end

  def property("model", _opts) do
    %{"type" => "string", "const" => "artifact_only_quality_gate_operator_training_summary"}
  end

  def property("model_limits", opts) do
    model_limits = Keyword.fetch!(opts, :model_limits)

    %{
      "type" => "array",
      "const" => model_limits,
      "items" => %{
        "type" => "string",
        "enum" => model_limits
      }
    }
  end

  def property(field, opts) when field in @stable_id_fields do
    %{"type" => "string", "pattern" => Keyword.fetch!(opts, :stable_id_pattern)}
  end

  def property(field, _opts) when field in @count_fields do
    %{"type" => "integer", "minimum" => 0}
  end

  def property("operator_training_requirement_counts", _opts) do
    CommonJsonSchema.non_negative_integer_count_map()
  end

  def property(field, opts) when field in @stable_id_array_map_fields do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> CommonJsonSchema.stable_id_array_map()
  end

  def property(field, _opts) when field in @string_array_fields do
    CommonJsonSchema.string_array()
  end

  def property("operator_training_review_required", _opts) do
    %{"type" => "boolean"}
  end

  def property("assumptions", _opts) do
    %{"type" => "object", "additionalProperties" => true}
  end

  defp fetch_dep!(deps, key) do
    Keyword.fetch!(deps, key)
  end
end
