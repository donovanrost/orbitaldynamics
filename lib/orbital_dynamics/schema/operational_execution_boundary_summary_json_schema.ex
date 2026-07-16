defmodule OrbitalDynamics.Schema.OperationalExecutionBoundarySummaryJsonSchema do
  @moduledoc false

  @count_fields [
    "gate_count",
    "passed_gate_count",
    "review_gate_count",
    "analysis_gate_count",
    "blocked_gate_count",
    "non_passed_gate_count"
  ]

  @boolean_fields [
    "import_eligible",
    "handoff_only",
    "execution_allowed",
    "cadence_write_allowed",
    "operator_authority_granted"
  ]

  def property_field?(field)
      when field in [
             "schema_contract",
             "source",
             "model",
             "model_limits",
             "readiness_level",
             "import_classification",
             "status",
             "execution_boundary",
             "analysis_mode",
             "analysis_mode_source",
             "operational_mode_gate",
             "non_passed_gate_ids",
             "assumptions"
           ],
      do: true

  def property_field?(field) when field in @count_fields, do: true
  def property_field?(field) when field in @boolean_fields, do: true
  def property_field?(_field), do: false

  def property_opts("model_limits", deps) do
    [model_limits: fetch_dep!(deps, :model_limits)]
  end

  def property_opts(field, deps)
      when field in ["readiness_level", "import_classification", "status", "analysis_mode"] do
    [capability: fetch_dep!(deps, :capability)]
  end

  def property_opts("operational_mode_gate", deps) do
    [gate_schema: fetch_dep!(deps, :gate_schema)]
  end

  def property_opts("non_passed_gate_ids", deps) do
    [string_array_schema: fetch_dep!(deps, :string_array_schema)]
  end

  def property_opts(_field, _deps), do: []

  def property_fun_from_context(deps) when is_list(deps) do
    fn field -> property_from_context(field, deps) end
  end

  def property_from_context(field, deps) when is_list(deps) do
    property(field, property_opts(field, deps))
  end

  def property("schema_contract", _opts) do
    %{"type" => "string", "const" => "operational_execution_boundary_summary.v1"}
  end

  def property("source", _opts) do
    %{"type" => "string", "enum" => ["operational_readiness_report.v1"]}
  end

  def property("model", _opts) do
    %{"type" => "string", "const" => "artifact_only_operational_execution_boundary_summary"}
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

  def property("readiness_level", opts) do
    %{
      "type" => "string",
      "enum" => capability(opts).readiness_levels
    }
  end

  def property("import_classification", opts) do
    %{
      "type" => "string",
      "enum" => capability(opts).import_classifications
    }
  end

  def property("status", opts) do
    %{
      "type" => "string",
      "enum" => capability(opts).gate_statuses
    }
  end

  def property(field, _opts) when field in @count_fields do
    %{"type" => "integer", "minimum" => 0}
  end

  def property(field, _opts) when field in @boolean_fields do
    %{"type" => "boolean"}
  end

  def property("execution_boundary", _opts) do
    %{
      "type" => "string",
      "enum" => [
        "adapter_handoff_only",
        "operator_review_required_before_import",
        "analysis_only_not_for_execution",
        "blocked_not_for_import_or_execution"
      ]
    }
  end

  def property("analysis_mode", opts) do
    %{
      "type" => "string",
      "enum" => capability(opts).analysis_modes
    }
  end

  def property("analysis_mode_source", _opts) do
    %{"type" => "string"}
  end

  def property("operational_mode_gate", opts) do
    Keyword.fetch!(opts, :gate_schema)
  end

  def property("non_passed_gate_ids", opts) do
    Keyword.fetch!(opts, :string_array_schema)
  end

  def property("assumptions", _opts) do
    %{"type" => "object", "additionalProperties" => true}
  end

  defp capability(opts) do
    Keyword.fetch!(opts, :capability)
  end

  defp fetch_dep!(deps, key), do: Keyword.fetch!(deps, key)
end
