defmodule OrbitalDynamics.Schema.TimelineDiffReportJsonSchema do
  @moduledoc false

  alias OrbitalDynamics.Schema.CommonJsonSchema

  @count_fields [
    "source_activity_count",
    "replacement_activity_count",
    "valid_source_activity_count",
    "valid_replacement_activity_count",
    "invalid_source_activity_input_count",
    "invalid_replacement_activity_input_count",
    "row_count",
    "added_count",
    "removed_count",
    "changed_count",
    "unchanged_count",
    "review_required_count",
    "duplicate_timeline_identity_count",
    "duplicate_source_timeline_identity_count",
    "duplicate_replacement_timeline_identity_count"
  ]

  @stable_id_array_fields [
    "invalid_source_activity_input_ids",
    "invalid_replacement_activity_input_ids"
  ]

  @enum_count_map_fields [
    "diff_status_counts",
    "required_operator_action_counts",
    "transition_decision_counts",
    "status_transition_counts",
    "approval_transition_counts",
    "status_transition_category_counts",
    "approval_transition_category_counts"
  ]

  def property_field?(field)
      when field in [
             "source",
             "model",
             "model_limits",
             "rows",
             "changed_field_counts"
           ],
      do: true

  def property_field?(field)
      when field in @count_fields or field in @stable_id_array_fields or
             field in @enum_count_map_fields,
      do: true

  def property_field?(_field), do: false

  def property_opts("model_limits", deps) do
    [model_limits: fetch_dep!(deps, :model_limits)]
  end

  def property_opts("rows", deps) do
    [row_schema: fetch_dep!(deps, :row_schema)]
  end

  def property_opts(field, deps) when field in @stable_id_array_fields do
    [stable_id_pattern: fetch_dep!(deps, :stable_id_pattern)]
  end

  def property_opts(field, deps) when field in @enum_count_map_fields do
    [capability: fetch_dep!(deps, :capability)]
  end

  def property_opts(_field, _deps), do: []

  def property_from_context(field, deps) when is_list(deps) do
    property(field, property_opts(field, deps))
  end

  def property_fun_from_context(deps) when is_list(deps) do
    fn field -> property_from_context(field, deps) end
  end

  def row_from_context(
        capability,
        stable_id_pattern,
        stable_id_array_schema,
        activity_context_schema,
        protection_decision_schema,
        lifecycle_transition_schema,
        string_array_schema,
        timeline_identity_schema
      ) do
    row(
      capability: capability,
      stable_id_pattern: stable_id_pattern,
      stable_id_array_schema: stable_id_array_schema,
      activity_context_schema: activity_context_schema,
      protection_decision_schema: protection_decision_schema,
      lifecycle_transition_schema: lifecycle_transition_schema,
      string_array_schema: string_array_schema,
      timeline_identity_schema: timeline_identity_schema
    )
  end

  def row_from_context(deps) when is_list(deps) do
    row(
      capability: fetch_dep!(deps, :capability),
      stable_id_pattern: fetch_dep!(deps, :stable_id_pattern),
      stable_id_array_schema: fetch_dep!(deps, :stable_id_array_schema),
      activity_context_schema: fetch_dep!(deps, :activity_context_schema),
      protection_decision_schema: fetch_dep!(deps, :protection_decision_schema),
      lifecycle_transition_schema: fetch_dep!(deps, :lifecycle_transition_schema),
      string_array_schema: fetch_dep!(deps, :string_array_schema),
      timeline_identity_schema: fetch_dep!(deps, :timeline_identity_schema)
    )
  end

  def row(opts) do
    capability = Keyword.fetch!(opts, :capability)
    stable_id_pattern = Keyword.fetch!(opts, :stable_id_pattern)
    stable_id_array_schema = Keyword.fetch!(opts, :stable_id_array_schema)

    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => [
        "id",
        "rank",
        "timeline_id",
        "diff_status",
        "changed_fields",
        "requires_operator_review",
        "required_operator_action",
        "reason"
      ],
      "properties" => %{
        "id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "rank" => %{"type" => "integer"},
        "timeline_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "diff_status" => %{
          "type" => "string",
          "enum" => capability.timeline_diff_statuses
        },
        "transition_decision" => %{
          "type" => "string",
          "enum" => capability.transition_decisions
        },
        "transition_decision_reason" => %{"type" => "string"},
        "source_activity_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "replacement_activity_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "source_activity_type" => %{"type" => "string"},
        "replacement_activity_type" => %{"type" => "string"},
        "scenario_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "source_spacecraft_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "replacement_spacecraft_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "source_ground_station_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "replacement_ground_station_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "source_target_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "replacement_target_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "source_source_window_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "replacement_source_window_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "source_starts_at_s" => %{"type" => "number"},
        "source_ends_at_s" => %{"type" => "number"},
        "replacement_starts_at_s" => %{"type" => "number"},
        "replacement_ends_at_s" => %{"type" => "number"},
        "source_status" => %{"type" => "string"},
        "replacement_status" => %{"type" => "string"},
        "source_approval_status" => %{"type" => "string"},
        "replacement_approval_status" => %{"type" => "string"},
        "source_locked" => %{"type" => "boolean"},
        "replacement_locked" => %{"type" => "boolean"},
        "source_allow_overlap" => %{"type" => "boolean"},
        "replacement_allow_overlap" => %{"type" => "boolean"},
        "source_activity_context" => Keyword.fetch!(opts, :activity_context_schema),
        "replacement_activity_context" => Keyword.fetch!(opts, :activity_context_schema),
        "source_protection_category" => %{"type" => "string"},
        "replacement_protection_category" => %{"type" => "string"},
        "source_protection_decision" => Keyword.fetch!(opts, :protection_decision_schema),
        "replacement_protection_decision" => Keyword.fetch!(opts, :protection_decision_schema),
        "source_protection_reason" => %{"type" => "string"},
        "replacement_protection_reason" => %{"type" => "string"},
        "status_transition" => Keyword.fetch!(opts, :lifecycle_transition_schema),
        "approval_transition" => Keyword.fetch!(opts, :lifecycle_transition_schema),
        "start_delta_s" => %{"type" => "number"},
        "end_delta_s" => %{"type" => "number"},
        "changed_fields" => Keyword.fetch!(opts, :string_array_schema),
        "requires_operator_review" => %{"type" => "boolean"},
        "required_operator_action" => %{
          "type" => "string",
          "enum" => capability.timeline_diff_required_operator_actions
        },
        "operator_action_reason" => %{"type" => "string"},
        "reason" => %{"type" => "string"},
        "source_timeline_identity" => Keyword.fetch!(opts, :timeline_identity_schema),
        "replacement_timeline_identity" => Keyword.fetch!(opts, :timeline_identity_schema),
        "timeline_identity_collision" => %{"type" => "boolean"},
        "duplicate_timeline_identity_scope" => %{"type" => "string"},
        "source_duplicate_activity_count" => %{"type" => "integer", "minimum" => 0},
        "replacement_duplicate_activity_count" => %{"type" => "integer", "minimum" => 0},
        "source_duplicate_activity_ids" => stable_id_array_schema,
        "replacement_duplicate_activity_ids" => stable_id_array_schema,
        "source_duplicate_activities" => %{
          "type" => "array",
          "items" => %{"type" => "object"}
        },
        "replacement_duplicate_activities" => %{
          "type" => "array",
          "items" => %{"type" => "object"}
        }
      }
    }
  end

  def property("source", _opts), do: %{"type" => "string"}

  def property("model", _opts) do
    %{"type" => "string", "const" => "timeline_identity_activity_diff"}
  end

  def property("model_limits", opts) do
    model_limits = Keyword.fetch!(opts, :model_limits)

    %{
      "type" => "array",
      "const" => model_limits,
      "items" => %{"type" => "string", "enum" => model_limits}
    }
  end

  def property("rows", opts) do
    %{"type" => "array", "items" => Keyword.fetch!(opts, :row_schema)}
  end

  def property(field, _opts) when field in @count_fields do
    %{"type" => "integer", "minimum" => 0}
  end

  def property(field, opts)
      when field in @stable_id_array_fields do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> CommonJsonSchema.stable_id_array()
  end

  def property(field, opts)
      when field in @enum_count_map_fields do
    opts
    |> Keyword.fetch!(:capability)
    |> capability_values(field)
    |> CommonJsonSchema.enum_count_map()
  end

  def property("changed_field_counts", _opts),
    do: CommonJsonSchema.non_negative_integer_count_map()

  defp capability_values(capability, "diff_status_counts"), do: capability.timeline_diff_statuses

  defp capability_values(capability, "required_operator_action_counts"),
    do: capability.timeline_diff_required_operator_actions

  defp capability_values(capability, "transition_decision_counts"),
    do: capability.transition_decisions

  defp capability_values(capability, "status_transition_counts"),
    do: capability.lifecycle_transition_types

  defp capability_values(capability, "approval_transition_counts"),
    do: capability.lifecycle_transition_types

  defp capability_values(capability, "status_transition_category_counts"),
    do: capability.status_transition_categories

  defp capability_values(capability, "approval_transition_category_counts"),
    do: capability.approval_transition_categories

  defp fetch_dep!(deps, key) do
    case Keyword.fetch!(deps, key) do
      fun when is_function(fun, 0) -> fun.()
      value -> value
    end
  end
end
