defmodule OrbitalDynamics.Schema.TimelineFeedbackReportJsonSchema do
  @moduledoc false

  alias OrbitalDynamics.Schema.CommonJsonSchema

  @count_fields [
    "planned_count",
    "realized_count",
    "row_count",
    "execution_uncertainty_declared_count",
    "execution_uncertainty_missing_count",
    "operational_feedback_excluded_count",
    "ambiguous_timeline_match_count",
    "ambiguous_timeline_feedback_count",
    "duplicate_realized_match_count",
    "duplicate_realized_feedback_count"
  ]

  @enum_count_fields [
    "status_counts",
    "feedback_kind_counts",
    "match_strategy_counts",
    "cadence_import_status_counts",
    "planned_protection_decision_counts"
  ]

  @object_fields [
    "assumptions",
    "cadence_import_manifest",
    "operator_review_package"
  ]

  @property_fields [
    "schema_contract",
    "rows",
    "model",
    "model_limits",
    "operational_feedback",
    "operational_feedback_provenance"
    | @count_fields ++ @enum_count_fields ++ @object_fields
  ]

  def property_field?(field) when field in @property_fields, do: true
  def property_field?(_field), do: false

  def property_from_context(
        field,
        row_schema,
        model_limits,
        capability,
        operational_feedback_schema,
        operational_feedback_provenance_schema
      ) do
    deps = [
      row_schema: row_schema,
      model_limits: model_limits,
      capability: capability,
      operational_feedback_schema: operational_feedback_schema,
      operational_feedback_provenance_schema: operational_feedback_provenance_schema
    ]

    property(field, property_opts(field, deps))
  end

  def property_fun_from_context(
        row_schema,
        model_limits,
        capability,
        operational_feedback_schema,
        operational_feedback_provenance_schema
      ) do
    fn field ->
      property_from_context(
        field,
        row_schema,
        model_limits,
        capability,
        operational_feedback_schema,
        operational_feedback_provenance_schema
      )
    end
  end

  def property_fun_from_context(deps) when is_list(deps) do
    fn field ->
      property(field, property_opts(field, deps))
    end
  end

  def property_opts("rows", deps) do
    [row_schema: fetch_dep!(deps, :row_schema)]
  end

  def property_opts("model_limits", deps) do
    [model_limits: fetch_dep!(deps, :model_limits)]
  end

  def property_opts(field, deps) when field in @enum_count_fields do
    [capability: fetch_dep!(deps, :capability)]
  end

  def property_opts("operational_feedback", deps) do
    [operational_feedback_schema: fetch_dep!(deps, :operational_feedback_schema)]
  end

  def property_opts("operational_feedback_provenance", deps) do
    [
      operational_feedback_provenance_schema:
        fetch_dep!(deps, :operational_feedback_provenance_schema)
    ]
  end

  def property_opts(_field, _deps), do: []

  def property("schema_contract", _opts) do
    %{
      "type" => "string",
      "const" => "timeline_feedback_report.v1",
      "description" => "Stable executable contract identifier"
    }
  end

  def property("rows", opts) do
    %{
      "type" => "array",
      "items" => Keyword.fetch!(opts, :row_schema)
    }
  end

  def property("model", _opts) do
    %{
      "type" => "string",
      "const" => "planned_vs_realized_activity_reconciliation"
    }
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

  def property(field, opts) when field in @enum_count_fields do
    capability = Keyword.fetch!(opts, :capability)

    field
    |> enum_count_values(capability)
    |> CommonJsonSchema.enum_count_map()
  end

  def property(field, _opts) when field in @object_fields do
    %{"type" => "object"}
  end

  def property("operational_feedback", opts) do
    Keyword.fetch!(opts, :operational_feedback_schema)
  end

  def property("operational_feedback_provenance", opts) do
    Keyword.fetch!(opts, :operational_feedback_provenance_schema)
  end

  defp enum_count_values("status_counts", capability), do: capability.report_statuses
  defp enum_count_values("feedback_kind_counts", capability), do: capability.feedback_kinds
  defp enum_count_values("match_strategy_counts", capability), do: capability.match_strategies

  defp enum_count_values("cadence_import_status_counts", capability),
    do: capability.cadence_import_statuses

  defp enum_count_values("planned_protection_decision_counts", capability),
    do: capability.planned_protection_decisions

  defp fetch_dep!(deps, key) do
    case Keyword.fetch!(deps, key) do
      fun when is_function(fun, 0) -> fun.()
      value -> value
    end
  end
end
