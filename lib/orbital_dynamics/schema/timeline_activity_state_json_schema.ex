defmodule OrbitalDynamics.Schema.TimelineActivityStateJsonSchema do
  @moduledoc false

  alias OrbitalDynamics.Schema.CommonJsonSchema

  @enum_count_fields [
    "status_counts",
    "feedback_kind_counts",
    "match_strategy_counts",
    "cadence_import_status_counts",
    "planned_protection_decision_counts"
  ]

  @count_map_fields [
    "realized_provider_counts",
    "realized_source_quality_counts"
  ]

  @stable_id_fields [
    "activity_id",
    "timeline_id",
    "planned_timeline_id",
    "realized_timeline_id"
  ]

  @stable_id_array_fields [
    "activity_ids",
    "review_activity_ids"
  ]

  @string_fields [
    "feedback_status",
    "planned_approval_category",
    "planned_approval_status",
    "planned_protection_category",
    "planned_protection_reason",
    "planned_status",
    "planned_status_category",
    "realized_approval_category",
    "realized_approval_status",
    "realized_status",
    "realized_status_category",
    "realized_trust_boundary_status"
  ]

  @boolean_fields [
    "review_required",
    "planned_locked",
    "realized_locked",
    "planned_executed",
    "realized_executed"
  ]

  @activity_context_fields [
    "source_activity_context",
    "realized_activity_context"
  ]

  @lifecycle_transition_fields [
    "status_transition",
    "approval_transition"
  ]

  @protection_decision_fields [
    "source_protection_decision",
    "realized_protection_decision"
  ]

  def property("rows", opts) do
    %{
      "type" => "array",
      "items" => Keyword.fetch!(opts, :row_schema)
    }
  end

  def property("schema_contract", opts) do
    %{"type" => "string", "const" => Keyword.fetch!(opts, :schema_contract)}
  end

  def property("model", _opts) do
    %{"type" => "string", "const" => "artifact_only_timeline_activity_state"}
  end

  def property("validation_level", _opts) do
    %{"type" => "string", "const" => "artifact_contract"}
  end

  def property("row_count", _opts) do
    %{"type" => "integer", "minimum" => 0}
  end

  def property(field, opts) when field in @enum_count_fields do
    capability = Keyword.fetch!(opts, :capability)

    field
    |> enum_count_values(capability)
    |> CommonJsonSchema.enum_count_map()
  end

  def property(field, _opts) when field in @count_map_fields do
    CommonJsonSchema.non_negative_integer_count_map()
  end

  def property(field, opts) when field in @stable_id_fields do
    %{"type" => "string", "pattern" => Keyword.fetch!(opts, :stable_id_pattern)}
  end

  def property(field, opts) when field in @stable_id_array_fields do
    Keyword.fetch!(opts, :stable_id_array_schema)
  end

  def property("realized_trust_boundaries", opts) do
    Keyword.fetch!(opts, :string_array_schema)
  end

  def property(field, _opts) when field in @boolean_fields do
    %{"type" => "boolean"}
  end

  def property("state_status", opts) do
    %{
      "type" => "string",
      "enum" => ["empty", "review_required" | Keyword.fetch!(opts, :report_statuses)]
    }
  end

  def property("feedback_kind", opts) do
    %{"type" => "string", "enum" => Keyword.fetch!(opts, :feedback_kinds)}
  end

  def property("match_strategy", opts) do
    %{"type" => "string", "enum" => Keyword.fetch!(opts, :match_strategies)}
  end

  def property(field, _opts) when field in @string_fields do
    %{"type" => "string"}
  end

  def property("planned_protection_decision", opts) do
    %{"type" => "string", "enum" => Keyword.fetch!(opts, :planned_protection_decisions)}
  end

  def property("timeline_identity", opts) do
    Keyword.fetch!(opts, :timeline_identity_schema)
  end

  def property(field, opts) when field in @activity_context_fields do
    Keyword.fetch!(opts, :activity_context_schema)
  end

  def property(field, opts) when field in @lifecycle_transition_fields do
    Keyword.fetch!(opts, :lifecycle_transition_schema)
  end

  def property(field, opts) when field in @protection_decision_fields do
    Keyword.fetch!(opts, :protection_decision_schema)
  end

  def property("assumptions", opts) do
    Keyword.fetch!(opts, :assumptions_schema)
  end

  def property("model_limits", opts) do
    model_limits = Keyword.fetch!(opts, :model_limits)

    %{
      "type" => "array",
      "const" => model_limits,
      "items" => %{"type" => "string", "enum" => model_limits}
    }
  end

  defp enum_count_values("status_counts", capability), do: capability.report_statuses
  defp enum_count_values("feedback_kind_counts", capability), do: capability.feedback_kinds
  defp enum_count_values("match_strategy_counts", capability), do: capability.match_strategies

  defp enum_count_values("cadence_import_status_counts", capability),
    do: capability.cadence_import_statuses

  defp enum_count_values("planned_protection_decision_counts", capability),
    do: capability.planned_protection_decisions
end
