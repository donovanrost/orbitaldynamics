defmodule OrbitalDynamics.Schema.TimelinePublicationSummaryJsonSchema do
  @moduledoc false

  alias OrbitalDynamics.Schema.CommonJsonSchema

  @stable_id_fields [
    "publication_id",
    "publication_authority",
    "source_artifact_id"
  ]

  @count_fields [
    "dependency_impact_row_count",
    "timeline_diff_row_count",
    "timeline_diff_changed_count",
    "timeline_diff_review_required_count"
  ]

  @count_map_fields [
    "changed_field_counts",
    "downstream_invalidation_reason_counts"
  ]

  @stable_id_array_fields [
    "supersedes_artifact_ids",
    "downstream_product_ids",
    "invalidated_downstream_product_ids",
    "impacted_source_activity_ids",
    "impacted_source_timeline_ids",
    "dependent_activity_ids",
    "dependent_timeline_ids",
    "source_dependent_activity_ids",
    "source_dependent_timeline_ids",
    "replacement_dependent_activity_ids",
    "replacement_dependent_timeline_ids",
    "impacted_dependency_activity_ids",
    "impacted_dependency_timeline_ids",
    "impacted_exclusive_with_activity_ids",
    "impacted_exclusive_with_timeline_ids",
    "changed_timeline_ids",
    "review_timeline_ids"
  ]

  @stable_id_array_map_fields [
    "timeline_ids_by_changed_field",
    "invalidated_downstream_product_ids_by_reason"
  ]

  def property("schema_contract", opts) do
    %{"type" => "string", "const" => Keyword.fetch!(opts, :schema_contract)}
  end

  def property("model", _opts) do
    %{"type" => "string", "const" => "artifact_only_timeline_publication_summary"}
  end

  def property("validation_level", _opts) do
    %{"type" => "string", "const" => "artifact_contract"}
  end

  def property("source", _opts) do
    %{"type" => "string"}
  end

  def property(field, opts) when field in @stable_id_fields do
    %{"type" => "string", "pattern" => Keyword.fetch!(opts, :stable_id_pattern)}
  end

  def property("source_artifact_type", _opts) do
    %{"type" => "string", "minLength" => 1}
  end

  def property("publication_sequence", _opts) do
    %{"type" => "integer", "minimum" => 0}
  end

  def property("publication_status", _opts) do
    %{
      "type" => "string",
      "enum" => ["published", "published_with_downstream_invalidations", "review_required"]
    }
  end

  def property("downstream_invalidation_status", _opts) do
    %{"type" => "string", "enum" => ["clear", "invalidated"]}
  end

  def property("dependency_impact_status", _opts) do
    %{"type" => "string", "enum" => ["clear", "not_evaluated", "review_required"]}
  end

  def property("source_timeline_diff_summary", opts) do
    Keyword.fetch!(opts, :timeline_diff_summary_source_schema)
  end

  def property("source_timeline_dependency_impact_summary", opts) do
    Keyword.fetch!(opts, :timeline_dependency_impact_summary_source_schema)
  end

  def property(field, _opts) when field in @count_fields do
    %{"type" => "integer", "minimum" => 0}
  end

  def property(field, _opts) when field in @count_map_fields do
    CommonJsonSchema.non_negative_integer_count_map()
  end

  def property(field, opts) when field in @stable_id_array_fields do
    Keyword.fetch!(opts, :stable_id_array_schema)
  end

  def property(field, opts) when field in @stable_id_array_map_fields do
    Keyword.fetch!(opts, :stable_id_array_map_schema)
  end

  def property("assumptions", _opts) do
    %{"type" => "object", "additionalProperties" => true}
  end

  def property("model_limits", opts) do
    model_limits = Keyword.fetch!(opts, :model_limits)

    %{
      "type" => "array",
      "const" => model_limits,
      "items" => %{"type" => "string", "enum" => model_limits}
    }
  end
end
