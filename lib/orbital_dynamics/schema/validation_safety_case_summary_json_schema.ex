defmodule OrbitalDynamics.Schema.ValidationSafetyCaseSummaryJsonSchema do
  @moduledoc false

  alias OrbitalDynamics.Schema.CommonJsonSchema

  @count_fields [
    "schema_version",
    "evidence_count",
    "blocked_evidence_count",
    "review_required_evidence_count",
    "accepted_evidence_count",
    "model_accepted_count",
    "model_review_required_count",
    "model_blocked_count",
    "unknown_model_count",
    "readiness_review_required_count",
    "readiness_blocked_count",
    "ready_for_import_count",
    "quality_gate_review_count",
    "quality_gate_blocked_count",
    "schema_error_count",
    "schema_warning_count",
    "schema_validation_report_count",
    "schema_validation_failed_report_count",
    "fixture_passed_count",
    "fixture_failed_count"
  ]

  @evidence_ref_map_fields [
    "evidence_refs_by_status",
    "evidence_refs_by_contract"
  ]

  @stable_id_fields [
    "case_id",
    "summary_id"
  ]

  def property_field?(field)
      when field in [
             "source",
             "model",
             "model_limits",
             "status",
             "input_contracts",
             "evidence_status_counts",
             "evidence"
           ],
      do: true

  def property_field?(field) when field in @count_fields, do: true
  def property_field?(field) when field in @evidence_ref_map_fields, do: true
  def property_field?(field) when field in @stable_id_fields, do: true
  def property_field?(_field), do: false

  def property_from_context(
        field,
        stable_id_pattern,
        model_limits,
        safety_case_statuses,
        evidence_row_schema
      ) do
    deps = [
      stable_id_pattern: stable_id_pattern,
      model_limits: model_limits,
      safety_case_statuses: safety_case_statuses,
      evidence_row_schema: evidence_row_schema
    ]

    property(field, property_opts(field, deps))
  end

  def property_from_context(field, deps) when is_list(deps) do
    property(field, property_opts(field, deps))
  end

  def property_fun_from_context(deps) when is_list(deps) do
    fn field ->
      property_from_context(field, deps)
    end
  end

  def property_fun_from_context(
        stable_id_pattern,
        model_limits,
        safety_case_statuses,
        evidence_row_schema
      ) do
    deps = [
      stable_id_pattern: stable_id_pattern,
      model_limits: model_limits,
      safety_case_statuses: safety_case_statuses,
      evidence_row_schema: evidence_row_schema
    ]

    fn field ->
      property_from_context(field, deps)
    end
  end

  def property_opts(field, deps) when field in @stable_id_fields do
    [stable_id_pattern: fetch_dep!(deps, :stable_id_pattern)]
  end

  def property_opts("model_limits", deps) do
    [model_limits: fetch_dep!(deps, :model_limits)]
  end

  def property_opts("status", deps) do
    [safety_case_statuses: fetch_dep!(deps, :safety_case_statuses)]
  end

  def property_opts(field, deps) when field in @evidence_ref_map_fields do
    [stable_id_pattern: fetch_dep!(deps, :stable_id_pattern)]
  end

  def property_opts("evidence", deps) do
    [evidence_row_schema: fetch_dep!(deps, :evidence_row_schema)]
  end

  def property_opts(_field, _deps), do: []

  def property(field, opts) when field in @stable_id_fields do
    %{"type" => "string", "pattern" => Keyword.fetch!(opts, :stable_id_pattern)}
  end

  def property("source", _opts) do
    %{"type" => "string"}
  end

  def property("model", _opts) do
    %{"type" => "string", "const" => "artifact_only_validation_safety_case_summary"}
  end

  def property("model_limits", opts) do
    model_limits = Keyword.fetch!(opts, :model_limits)

    %{
      "type" => "array",
      "const" => model_limits,
      "items" => %{"type" => "string", "enum" => model_limits}
    }
  end

  def property(field, _opts) when field in @count_fields do
    %{"type" => "integer", "minimum" => 0}
  end

  def property("status", opts) do
    %{"type" => "string", "enum" => Keyword.fetch!(opts, :safety_case_statuses)}
  end

  def property("input_contracts", _opts) do
    CommonJsonSchema.string_array()
  end

  def property("evidence_status_counts", _opts) do
    CommonJsonSchema.non_negative_integer_count_map()
  end

  def property(field, opts) when field in @evidence_ref_map_fields do
    %{
      "type" => "object",
      "additionalProperties" =>
        opts
        |> Keyword.fetch!(:stable_id_pattern)
        |> CommonJsonSchema.stable_id_array()
    }
  end

  def property("evidence", opts) do
    %{
      "type" => "array",
      "items" => Keyword.fetch!(opts, :evidence_row_schema)
    }
  end

  defp fetch_dep!(deps, key) do
    case Keyword.fetch!(deps, key) do
      fun when is_function(fun, 0) -> fun.()
      value -> value
    end
  end
end
