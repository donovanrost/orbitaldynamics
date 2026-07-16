defmodule OrbitalDynamics.Schema.QualityGateReportJsonSchema do
  @moduledoc false

  alias OrbitalDynamics.Schema.CandidateRefreshReportJsonSchema
  alias OrbitalDynamics.Schema.CommonJsonSchema
  alias OrbitalDynamics.Schema.OperationalReadinessContextJsonSchema

  @count_map_fields [
    "gate_status_counts",
    "gate_classification_counts"
  ]

  @boolean_fields [
    "handoff_only",
    "execution_allowed",
    "cadence_write_allowed",
    "operator_authority_granted"
  ]

  @stable_id_array_map_fields [
    "gate_ids_by_status",
    "gate_ids_by_classification",
    "quality_gate_row_ids_by_status",
    "quality_gate_row_ids_by_classification"
  ]

  @stable_id_array_fields [
    "passed_gate_ids",
    "review_required_gate_ids",
    "analysis_only_gate_ids",
    "blocked_gate_ids"
  ]

  @gate_count_fields [
    "gate_count",
    "passed_gate_count",
    "review_gate_count",
    "analysis_gate_count",
    "blocked_gate_count",
    "non_passed_gate_count"
  ]

  @capability_fields ["readiness_level", "import_classification", "status"]

  def property_field?(field)
      when field in ["model", "model_limits", "rows", "execution_boundary", "assumptions"],
      do: true

  def property_field?(field) when field in @capability_fields, do: true
  def property_field?(field) when field in @gate_count_fields, do: true
  def property_field?(field) when field in @count_map_fields, do: true
  def property_field?(field) when field in @boolean_fields, do: true
  def property_field?(field) when field in @stable_id_array_map_fields, do: true
  def property_field?(field) when field in @stable_id_array_fields, do: true
  def property_field?(_field), do: false

  def property_opts(field, deps) when field in @capability_fields do
    [capability: fetch_dep!(deps, :capability)]
  end

  def property_opts("model_limits", deps) do
    [model_limits: fetch_dep!(deps, :model_limits)]
  end

  def property_opts("rows", deps) do
    [row_schema: fetch_dep!(deps, :row_schema)]
  end

  def property_opts(field, deps)
      when field in @stable_id_array_map_fields or field in @stable_id_array_fields do
    [stable_id_pattern: fetch_dep!(deps, :stable_id_pattern)]
  end

  def property_opts(_field, _deps), do: []

  def property_fun_from_context(deps) when is_list(deps) do
    fn field -> property_from_context(field, deps) end
  end

  def property_from_context(field, deps) when is_list(deps) do
    property(field, property_opts(field, deps))
  end

  def property("readiness_level", opts) do
    %{
      "type" => "string",
      "enum" => Keyword.fetch!(opts, :capability).readiness_levels
    }
  end

  def property("import_classification", opts) do
    %{
      "type" => "string",
      "enum" => Keyword.fetch!(opts, :capability).import_classifications
    }
  end

  def property("status", opts) do
    %{
      "type" => "string",
      "enum" => Keyword.fetch!(opts, :capability).gate_statuses
    }
  end

  def property(field, _opts) when field in @gate_count_fields do
    %{"type" => "integer", "minimum" => 0}
  end

  def property("model", _opts) do
    %{"type" => "string", "const" => "artifact_only_operational_quality_gate_report"}
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

  def property("rows", opts) do
    %{
      "type" => "array",
      "items" => Keyword.fetch!(opts, :row_schema)
    }
  end

  def property(field, _opts) when field in @count_map_fields do
    CommonJsonSchema.non_negative_integer_count_map()
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

  def property(field, opts) when field in @stable_id_array_map_fields do
    %{
      "type" => "object",
      "additionalProperties" =>
        opts
        |> Keyword.fetch!(:stable_id_pattern)
        |> CommonJsonSchema.stable_id_array()
    }
  end

  def property(field, opts) when field in @stable_id_array_fields do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> CommonJsonSchema.stable_id_array()
  end

  def property("assumptions", _opts) do
    %{"type" => "object", "additionalProperties" => true}
  end

  def row(opts) do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => ["id", "rank", "gate_id", "status", "classification", "reason"],
      "properties" => row_properties(opts)
    }
  end

  defp row_properties(opts) do
    capability = Keyword.fetch!(opts, :capability)
    stable_id_pattern = Keyword.fetch!(opts, :stable_id_pattern)

    %{
      "id" => %{"type" => "string", "pattern" => stable_id_pattern},
      "rank" => %{"type" => "integer", "minimum" => 1},
      "gate_id" => %{"type" => "string", "enum" => capability.gates},
      "status" => %{"type" => "string", "enum" => capability.gate_statuses},
      "classification" => %{
        "type" => "string",
        "enum" => capability.import_classifications
      },
      "reason" => %{"type" => "string"},
      "analysis_mode" => %{"type" => "string", "enum" => capability.analysis_modes},
      "analysis_mode_source" => %{"type" => "string"},
      "source_operational_readiness_gate" => Keyword.fetch!(opts, :gate_schema)
    }
    |> Map.merge(
      OperationalReadinessContextJsonSchema.resource_context_properties(
        stable_id_pattern: stable_id_pattern
      )
    )
    |> Map.merge(OperationalReadinessContextJsonSchema.operator_training_context_properties())
    |> Map.merge(OperationalReadinessContextJsonSchema.adapter_boundary_context_properties())
    |> Map.merge(OperationalReadinessContextJsonSchema.cadence_import_context_properties())
    |> Map.merge(
      CandidateRefreshReportJsonSchema.timeline_publication_context_properties(
        stable_id_pattern: stable_id_pattern
      )
    )
  end

  defp fetch_dep!(deps, key), do: Keyword.fetch!(deps, key)
end
