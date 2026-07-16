defmodule OrbitalDynamics.Schema.OperationalQualityGateImportReadinessSummaryJsonSchema do
  @moduledoc false

  alias OrbitalDynamics.Schema.CommonJsonSchema

  @stable_id_fields [
    "source_artifact_id",
    "source_quality_gate_report_id",
    "source_readiness_report_id"
  ]

  @count_fields [
    "import_readiness_row_count",
    "ready_for_import_count",
    "manifest_review_required_count",
    "blocked_import_count",
    "missing_import_count",
    "invalid_cadence_import_count",
    "current_freshness_count",
    "stale_freshness_count",
    "unknown_freshness_count",
    "dependency_impact_row_count",
    "timeline_diff_row_count",
    "timeline_diff_changed_count",
    "timeline_diff_review_required_count"
  ]

  @count_map_fields [
    "freshness_status_counts",
    "import_status_counts",
    "cadence_import_status_counts",
    "publication_status_counts",
    "downstream_invalidation_status_counts",
    "downstream_invalidation_reason_counts",
    "dependency_impact_status_counts",
    "publication_authority_counts",
    "source_artifact_type_counts",
    "changed_field_counts"
  ]

  @stable_id_array_map_fields [
    "quality_gate_row_ids_by_status",
    "quality_gate_ids_by_status",
    "timeline_ids_by_changed_field",
    "invalidated_downstream_product_ids_by_reason"
  ]

  @string_array_fields [
    "freshness_status_ids",
    "import_status_ids",
    "cadence_import_status_ids",
    "publication_ids",
    "source_artifact_ids",
    "supersedes_artifact_ids",
    "downstream_product_ids",
    "invalidated_downstream_product_ids",
    "impacted_dependency_activity_ids",
    "impacted_dependency_timeline_ids",
    "impacted_exclusive_with_activity_ids",
    "impacted_exclusive_with_timeline_ids",
    "changed_timeline_ids",
    "review_timeline_ids",
    "review_required_quality_gate_row_ids",
    "blocked_quality_gate_row_ids",
    "ready_quality_gate_row_ids",
    "stale_or_unknown_freshness_quality_gate_row_ids",
    "import_preparation_quality_gate_row_ids",
    "blocked_import_quality_gate_row_ids",
    "import_readiness_gate_ids"
  ]

  @boolean_fields [
    "freshness_review_required",
    "import_preparation_required",
    "import_blocked"
  ]

  def property_field?(field)
      when field in [
             "schema_contract",
             "source",
             "model",
             "model_limits",
             "analysis_only_quality_gate_row_ids",
             "assumptions"
           ],
      do: true

  def property_field?(field) when field in @stable_id_fields, do: true
  def property_field?(field) when field in @count_fields, do: true
  def property_field?(field) when field in @count_map_fields, do: true
  def property_field?(field) when field in @stable_id_array_map_fields, do: true
  def property_field?(field) when field in @string_array_fields, do: true
  def property_field?(field) when field in @boolean_fields, do: true
  def property_field?(_field), do: false

  def property_opts("model_limits", deps) do
    [model_limits: fetch_dep!(deps, :model_limits)]
  end

  def property_opts("analysis_only_quality_gate_row_ids", deps) do
    [stable_id_pattern: fetch_dep!(deps, :stable_id_pattern)]
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
    %{"type" => "string", "const" => "operational_quality_gate_import_readiness_summary.v1"}
  end

  def property("source", _opts) do
    %{"type" => "string", "enum" => ["quality_gate_report.v1"]}
  end

  def property("model", _opts) do
    %{"type" => "string", "const" => "artifact_only_quality_gate_import_readiness_summary"}
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

  def property("analysis_only_quality_gate_row_ids", opts) do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> CommonJsonSchema.stable_id_array()
  end

  def property(field, opts) when field in @stable_id_fields do
    %{"type" => "string", "pattern" => Keyword.fetch!(opts, :stable_id_pattern)}
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

  def property(field, _opts) when field in @string_array_fields do
    CommonJsonSchema.string_array()
  end

  def property(field, _opts) when field in @boolean_fields do
    %{"type" => "boolean"}
  end

  def property("assumptions", _opts) do
    %{"type" => "object", "additionalProperties" => true}
  end

  defp fetch_dep!(deps, key) do
    Keyword.fetch!(deps, key)
  end
end
