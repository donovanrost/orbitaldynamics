defmodule OrbitalDynamics.Schema.TimelineActivityPreconditionSummaryJsonSchema do
  @moduledoc false

  @count_fields [
    "blocked_precondition_count",
    "review_precondition_count"
  ]

  @string_array_fields [
    "blocked_precondition_types",
    "review_precondition_types"
  ]

  @stable_id_fields [
    "activity_id",
    "timeline_id"
  ]

  @stable_id_array_fields [
    "dependency_activity_ids",
    "dependency_timeline_ids",
    "exclusive_with_activity_ids",
    "exclusive_with_timeline_ids"
  ]

  @boolean_fields [
    "allow_overlap",
    "invalid_activity_input"
  ]

  @string_fields [
    "activity_type",
    "invalid_activity_input_reason"
  ]

  def property("schema_contract", opts) do
    %{"type" => "string", "const" => Keyword.fetch!(opts, :schema_contract)}
  end

  def property("model", _opts) do
    %{
      "type" => "string",
      "const" => "artifact_only_timeline_activity_precondition_summary"
    }
  end

  def property("validation_level", _opts) do
    %{"type" => "string", "const" => "artifact_contract"}
  end

  def property("model_limits", opts) do
    model_limits = Keyword.fetch!(opts, :model_limits)

    %{
      "type" => "array",
      "const" => model_limits,
      "items" => %{"type" => "string", "enum" => model_limits}
    }
  end

  def property("precondition_status", opts) do
    %{"type" => "string", "enum" => Keyword.fetch!(opts, :precondition_statuses)}
  end

  def property(field, _opts) when field in @count_fields do
    %{"type" => "integer", "minimum" => 0}
  end

  def property(field, opts) when field in @string_array_fields do
    Keyword.fetch!(opts, :string_array_schema)
  end

  def property("preconditions", opts) do
    %{
      "type" => "array",
      "items" => Keyword.fetch!(opts, :precondition_schema)
    }
  end

  def property(field, opts) when field in @stable_id_fields do
    %{"type" => "string", "pattern" => Keyword.fetch!(opts, :stable_id_pattern)}
  end

  def property(field, opts) when field in @stable_id_array_fields do
    Keyword.fetch!(opts, :stable_id_array_schema)
  end

  def property(field, _opts) when field in @boolean_fields do
    %{"type" => "boolean"}
  end

  def property(field, _opts) when field in @string_fields do
    %{"type" => "string"}
  end

  def property("timeline_identity", opts) do
    Keyword.fetch!(opts, :timeline_identity_schema)
  end

  def property("source_activity", _opts) do
    %{"type" => "object", "additionalProperties" => true}
  end

  def property("assumptions", _opts) do
    %{"type" => "object", "additionalProperties" => true}
  end
end
