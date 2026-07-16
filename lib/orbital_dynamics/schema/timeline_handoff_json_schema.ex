defmodule OrbitalDynamics.Schema.TimelineHandoffJsonSchema do
  @moduledoc false

  def dependency_impact_properties(opts) do
    stable_id_array_schema = Keyword.fetch!(opts, :stable_id_array_schema)

    %{
      "dependency_impact_scope" => %{"type" => "string", "enum" => ["source", "replacement"]},
      "dependency_impact_status" => %{"type" => "string"},
      "changed_source_activity_count" => %{"type" => "integer", "minimum" => 0},
      "changed_source_timeline_count" => %{"type" => "integer", "minimum" => 0},
      "dependent_activity_count" => %{"type" => "integer", "minimum" => 0},
      "source_dependent_activity_count" => %{"type" => "integer", "minimum" => 0},
      "replacement_dependent_activity_count" => %{"type" => "integer", "minimum" => 0},
      "impacted_source_activity_ids" => stable_id_array_schema,
      "impacted_source_timeline_ids" => stable_id_array_schema,
      "dependent_activity_ids" => stable_id_array_schema,
      "dependent_timeline_ids" => stable_id_array_schema,
      "source_dependent_activity_ids" => stable_id_array_schema,
      "source_dependent_timeline_ids" => stable_id_array_schema,
      "replacement_dependent_activity_ids" => stable_id_array_schema,
      "replacement_dependent_timeline_ids" => stable_id_array_schema,
      "dependency_activity_ids" => stable_id_array_schema,
      "dependency_timeline_ids" => stable_id_array_schema,
      "exclusive_with_activity_ids" => stable_id_array_schema,
      "exclusive_with_timeline_ids" => stable_id_array_schema,
      "impacted_dependency_activity_ids" => stable_id_array_schema,
      "impacted_dependency_timeline_ids" => stable_id_array_schema,
      "impacted_exclusive_with_activity_ids" => stable_id_array_schema,
      "impacted_exclusive_with_timeline_ids" => stable_id_array_schema,
      "source_timeline_dependency_impact" =>
        Keyword.fetch!(opts, :timeline_dependency_impact_row_schema)
    }
  end

  def publication_properties(opts) do
    stable_id_pattern = Keyword.fetch!(opts, :stable_id_pattern)
    stable_id_array_schema = Keyword.fetch!(opts, :stable_id_array_schema)

    %{
      "publication_id" => %{"type" => "string", "pattern" => stable_id_pattern},
      "publication_sequence" => %{"type" => "integer", "minimum" => 0},
      "publication_status" => %{
        "type" => "string",
        "enum" => ["published", "published_with_downstream_invalidations", "review_required"]
      },
      "downstream_invalidation_status" => %{
        "type" => "string",
        "enum" => ["clear", "invalidated"]
      },
      "publication_authority" => %{"type" => "string", "pattern" => stable_id_pattern},
      "source_artifact_id" => %{"type" => "string", "pattern" => stable_id_pattern},
      "source_artifact_type" => %{"type" => "string", "minLength" => 1},
      "supersedes_artifact_ids" => stable_id_array_schema,
      "downstream_product_ids" => stable_id_array_schema,
      "invalidated_downstream_product_ids" => stable_id_array_schema,
      "dependency_impact_row_count" => %{"type" => "integer", "minimum" => 0},
      "timeline_diff_row_count" => %{"type" => "integer", "minimum" => 0},
      "timeline_diff_changed_count" => %{"type" => "integer", "minimum" => 0},
      "timeline_diff_review_required_count" => %{"type" => "integer", "minimum" => 0},
      "changed_field_counts" => Keyword.fetch!(opts, :count_map_schema),
      "changed_timeline_ids" => stable_id_array_schema,
      "review_timeline_ids" => stable_id_array_schema,
      "timeline_ids_by_changed_field" => Keyword.fetch!(opts, :stable_id_array_map_schema),
      "source_timeline_publication_summary" =>
        Keyword.fetch!(opts, :timeline_publication_summary_source_schema)
    }
  end

  def activity_precondition_properties(opts) do
    stable_id_array_schema = Keyword.fetch!(opts, :stable_id_array_schema)

    %{
      "precondition_status" => %{
        "type" => "string",
        "enum" => Keyword.fetch!(opts, :timeline_capability).activity_precondition_statuses
      },
      "blocked_precondition_count" => %{"type" => "integer", "minimum" => 0},
      "review_precondition_count" => %{"type" => "integer", "minimum" => 0},
      "blocked_precondition_types" => Keyword.fetch!(opts, :string_array_schema),
      "review_precondition_types" => Keyword.fetch!(opts, :string_array_schema),
      "preconditions" => %{
        "type" => "array",
        "items" => Keyword.fetch!(opts, :timeline_precondition_schema)
      },
      "dependency_activity_ids" => stable_id_array_schema,
      "dependency_timeline_ids" => stable_id_array_schema,
      "exclusive_with_activity_ids" => stable_id_array_schema,
      "exclusive_with_timeline_ids" => stable_id_array_schema,
      "allow_overlap" => %{"type" => "boolean"},
      "invalid_activity_input" => %{"type" => "boolean"},
      "invalid_activity_input_reason" => %{"type" => "string"},
      "source_timeline_activity_precondition_summary" =>
        Keyword.fetch!(opts, :timeline_activity_precondition_summary_source_schema)
    }
  end
end
