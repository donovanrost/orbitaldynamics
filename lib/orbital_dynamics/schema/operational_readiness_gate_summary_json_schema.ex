defmodule OrbitalDynamics.Schema.OperationalReadinessGateSummaryJsonSchema do
  @moduledoc false

  alias OrbitalDynamics.Schema.CommonJsonSchema

  @count_fields [
    "gate_count",
    "passed_gate_count",
    "review_gate_count",
    "analysis_gate_count",
    "blocked_gate_count",
    "non_passed_gate_count"
  ]

  @count_map_fields [
    "gate_status_counts",
    "gate_classification_counts"
  ]

  @stable_id_array_map_fields [
    "gate_ids_by_status",
    "gate_ids_by_classification"
  ]

  @stable_id_array_fields [
    "passed_gate_ids",
    "review_required_gate_ids",
    "analysis_only_gate_ids",
    "blocked_gate_ids",
    "non_passed_gate_ids"
  ]

  @gate_array_fields [
    "gates",
    "non_passed_gates"
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
             "assumptions"
           ],
      do: true

  def property_field?(field) when field in @count_fields, do: true
  def property_field?(field) when field in @count_map_fields, do: true
  def property_field?(field) when field in @stable_id_array_map_fields, do: true
  def property_field?(field) when field in @stable_id_array_fields, do: true
  def property_field?(field) when field in @gate_array_fields, do: true
  def property_field?(_field), do: false

  def property_opts("model_limits", deps) do
    [model_limits: fetch_dep!(deps, :model_limits)]
  end

  def property_opts(field, deps)
      when field in ["readiness_level", "import_classification", "status"] do
    [capability: fetch_dep!(deps, :capability)]
  end

  def property_opts(field, deps)
      when field in @stable_id_array_map_fields or field in @stable_id_array_fields do
    [stable_id_pattern: fetch_dep!(deps, :stable_id_pattern)]
  end

  def property_opts(field, deps) when field in @gate_array_fields do
    [gate_schema: fetch_dep!(deps, :gate_schema)]
  end

  def property_opts(_field, _deps), do: []

  def property_fun_from_context(deps) when is_list(deps) do
    fn field -> property_from_context(field, deps) end
  end

  def property_from_context(field, deps) when is_list(deps) do
    property(field, property_opts(field, deps))
  end

  def property("schema_contract", _opts) do
    %{"type" => "string", "const" => "operational_readiness_gate_summary.v1"}
  end

  def property("source", _opts) do
    %{"type" => "string", "enum" => ["operational_readiness_report.v1"]}
  end

  def property("model", _opts) do
    %{"type" => "string", "const" => "artifact_only_operational_readiness_gate_summary"}
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

  def property(field, opts) when field in @gate_array_fields do
    %{
      "type" => "array",
      "items" => Keyword.fetch!(opts, :gate_schema)
    }
  end

  def property("assumptions", _opts) do
    %{"type" => "object", "additionalProperties" => true}
  end

  defp capability(opts) do
    Keyword.fetch!(opts, :capability)
  end

  defp fetch_dep!(deps, key) do
    Keyword.fetch!(deps, key)
  end
end
