defmodule OrbitalDynamics.Schema.TimelineTransitionApplicationJsonSchema do
  @moduledoc false

  alias OrbitalDynamics.Schema.FocusedSourceJsonSchema

  @report "timeline_transition_application_report.v1"
  @summary "timeline_transition_application_summary.v1"

  @report_integer_fields [
    "source_activity_count",
    "replacement_activity_count",
    "application_count",
    "selected_activity_count",
    "review_required_count",
    "preserved_source_count",
    "recorded_replacement_count",
    "withheld_review_count",
    "selected_timeline_integrity_issue_count",
    "selected_timeline_integrity_review_count"
  ]

  @report_enum_count_fields [
    "application_status_counts",
    "transition_decision_counts",
    "required_operator_action_counts",
    "status_transition_counts",
    "approval_transition_counts",
    "status_transition_category_counts",
    "approval_transition_category_counts"
  ]

  @summary_integer_fields @report_integer_fields

  @summary_enum_count_fields [
    "application_status_counts",
    "transition_decision_counts",
    "required_operator_action_counts",
    "status_transition_category_counts",
    "approval_transition_category_counts"
  ]

  @summary_stable_id_array_fields [
    "selected_activity_ids",
    "selected_timeline_ids",
    "review_timeline_ids",
    "review_activity_ids",
    "preserved_source_timeline_ids",
    "recorded_replacement_timeline_ids",
    "withheld_review_timeline_ids"
  ]

  @summary_stable_id_array_map_fields [
    "review_timeline_ids_by_required_operator_action",
    "review_timeline_ids_by_status_transition_category",
    "review_timeline_ids_by_approval_transition_category"
  ]

  def property_field?(field, @report)
      when field in [
             "source",
             "model",
             "applications",
             "selected_activities",
             "model_limits",
             "selected_timeline_integrity_issue_types",
             "timeline_revision"
           ],
      do: true

  def property_field?(field, @report)
      when field in @report_integer_fields or field in @report_enum_count_fields,
      do: true

  def property_field?(field, @summary)
      when field in [
             "schema_contract",
             "model",
             "validation_level",
             "source_artifact_type",
             "source",
             "review_applications",
             "model_limits",
             "selected_timeline_integrity_issue_types",
             "assumptions",
             "timeline_revision"
           ],
      do: true

  def property_field?(field, @summary)
      when field in @summary_integer_fields or field in @summary_enum_count_fields or
             field in @summary_stable_id_array_fields or
             field in @summary_stable_id_array_map_fields,
      do: true

  def property_field?(_field, _contract_name), do: false

  def property_opts("applications", @report, deps) do
    [application_row_schema: fetch_dep!(deps, :application_row_schema)]
  end

  def property_opts("selected_activities", @report, deps) do
    [selected_activity_schema: fetch_dep!(deps, :selected_activity_schema)]
  end

  def property_opts("review_applications", @summary, deps) do
    [application_row_schema: fetch_dep!(deps, :application_row_schema)]
  end

  def property_opts("model_limits", contract_name, deps)
      when contract_name in [@report, @summary] do
    [model_limits: fetch_dep!(deps, :model_limits)]
  end

  def property_opts("selected_timeline_integrity_issue_types", contract_name, deps)
      when contract_name in [@report, @summary] do
    [timeline_capability: fetch_dep!(deps, :timeline_capability)]
  end

  def property_opts(field, @report, deps) when field in @report_enum_count_fields do
    [
      timeline_capability: fetch_dep!(deps, :timeline_capability),
      enum_count_map_schema: fetch_dep!(deps, :enum_count_map_schema)
    ]
  end

  def property_opts(field, @summary, deps) when field in @summary_enum_count_fields do
    [
      timeline_capability: fetch_dep!(deps, :timeline_capability),
      enum_count_map_schema: fetch_dep!(deps, :enum_count_map_schema)
    ]
  end

  def property_opts(field, @summary, deps) when field in @summary_stable_id_array_fields do
    [stable_id_array_schema: fetch_dep!(deps, :stable_id_array_schema)]
  end

  def property_opts(field, @summary, deps) when field in @summary_stable_id_array_map_fields do
    [stable_id_array_map_schema: fetch_dep!(deps, :stable_id_array_map_schema)]
  end

  def property_opts(_field, _contract_name, _deps), do: []

  def property_from_context(field, deps) when is_list(deps) do
    contract_name = fetch_dep!(deps, :contract_name)
    property(field, contract_name, property_opts(field, contract_name, deps))
  end

  def property_from_context(
        field,
        contract_name,
        application_row_schema,
        selected_activity_schema,
        model_limits,
        timeline_capability,
        enum_count_map_schema,
        stable_id_array_schema,
        stable_id_array_map_schema
      ) do
    deps =
      property_deps_from_context(
        application_row_schema,
        selected_activity_schema,
        model_limits,
        timeline_capability,
        enum_count_map_schema,
        stable_id_array_schema,
        stable_id_array_map_schema
      )

    property_from_context(field, Keyword.put(deps, :contract_name, contract_name))
  end

  def property_fun_from_context(deps) when is_list(deps) do
    fn field -> property_from_context(field, deps) end
  end

  def property_fun_from_context(
        contract_name,
        application_row_schema,
        selected_activity_schema,
        model_limits,
        timeline_capability,
        enum_count_map_schema,
        stable_id_array_schema,
        stable_id_array_map_schema
      ) do
    deps =
      property_deps_from_context(
        application_row_schema,
        selected_activity_schema,
        model_limits,
        timeline_capability,
        enum_count_map_schema,
        stable_id_array_schema,
        stable_id_array_map_schema
      )

    property_fun_from_context(Keyword.put(deps, :contract_name, contract_name))
  end

  def property_deps_from_context(
        application_row_schema,
        selected_activity_schema,
        model_limits,
        timeline_capability,
        enum_count_map_schema,
        stable_id_array_schema,
        stable_id_array_map_schema
      ) do
    [
      application_row_schema: application_row_schema,
      selected_activity_schema: selected_activity_schema,
      model_limits: model_limits,
      timeline_capability: timeline_capability,
      enum_count_map_schema: enum_count_map_schema,
      stable_id_array_schema: stable_id_array_schema,
      stable_id_array_map_schema: stable_id_array_map_schema
    ]
  end

  def source_from_context(
        schema_contract,
        contract,
        application_row_schema,
        selected_activity_schema,
        model_limits,
        timeline_capability,
        enum_count_map_schema,
        stable_id_array_schema,
        stable_id_array_map_schema,
        default_property
      ) do
    FocusedSourceJsonSchema.build(
      schema_contract,
      contract,
      &property_field?(&1, schema_contract),
      &property_opts(&1, schema_contract, &2),
      &property(&1, schema_contract, &2),
      property_deps_from_context(
        application_row_schema,
        selected_activity_schema,
        model_limits,
        timeline_capability,
        enum_count_map_schema,
        stable_id_array_schema,
        stable_id_array_map_schema
      ),
      default_property
    )
  end

  def summary_source_from_context(schema_contract, contract, deps, default_property) do
    application_row_schema = fn -> application_row_from_context(deps) end
    selected_activity_schema = fn -> selected_activity_from_context(deps) end

    source_from_context(
      schema_contract,
      contract,
      application_row_schema,
      selected_activity_schema,
      Keyword.fetch!(deps, :model_limits),
      Keyword.fetch!(deps, :timeline_capability),
      Keyword.fetch!(deps, :enum_count_map_schema),
      Keyword.fetch!(deps, :stable_id_array_schema),
      Keyword.fetch!(deps, :stable_id_array_map_schema),
      default_property
    )
  end

  def application_row_from_context(
        timeline_capability,
        stable_id_pattern,
        stable_id_array_schema,
        string_array_schema,
        lifecycle_transition_schema,
        protection_decision_schema,
        timeline_diff_row_schema
      ) do
    application_row(
      timeline_capability: timeline_capability,
      stable_id_pattern: stable_id_pattern,
      stable_id_array_schema: stable_id_array_schema,
      string_array_schema: string_array_schema,
      lifecycle_transition_schema: lifecycle_transition_schema,
      protection_decision_schema: protection_decision_schema,
      timeline_diff_row_schema: timeline_diff_row_schema
    )
  end

  def application_row_from_context(deps) when is_list(deps) do
    application_row(
      timeline_capability: fetch_dep!(deps, :timeline_capability),
      stable_id_pattern: fetch_dep!(deps, :stable_id_pattern),
      stable_id_array_schema: fetch_dep!(deps, :stable_id_array_schema),
      string_array_schema: fetch_dep!(deps, :string_array_schema),
      lifecycle_transition_schema: fetch_dep!(deps, :lifecycle_transition_schema),
      protection_decision_schema: fetch_dep!(deps, :protection_decision_schema),
      timeline_diff_row_schema: fetch_dep!(deps, :timeline_diff_row_schema)
    )
  end

  def application_row(opts) do
    capability = Keyword.fetch!(opts, :timeline_capability)
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
        "transition_decision",
        "requires_operator_review",
        "required_operator_action",
        "reason",
        "changed_fields",
        "application_status",
        "source_timeline_diff"
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
        "requires_operator_review" => %{"type" => "boolean"},
        "required_operator_action" => %{
          "type" => "string",
          "enum" => capability.timeline_diff_required_operator_actions
        },
        "reason" => %{"type" => "string"},
        "operator_action_reason" => %{"type" => "string"},
        "changed_fields" => Keyword.fetch!(opts, :string_array_schema),
        "status_transition" => Keyword.fetch!(opts, :lifecycle_transition_schema),
        "approval_transition" => Keyword.fetch!(opts, :lifecycle_transition_schema),
        "application_status" => %{"type" => "string"},
        "selected_activity_source" => %{"type" => "string"},
        "source_activity_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "replacement_activity_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "source_activity_type" => %{"type" => "string"},
        "replacement_activity_type" => %{"type" => "string"},
        "source_protection_decision" => Keyword.fetch!(opts, :protection_decision_schema),
        "replacement_protection_decision" => Keyword.fetch!(opts, :protection_decision_schema),
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
        },
        "selected_activity" => %{"type" => "object", "additionalProperties" => true},
        "selected_timeline_integrity_status" => %{"type" => "string"},
        "selected_timeline_integrity_issue_count" => %{
          "type" => "integer",
          "minimum" => 0
        },
        "selected_timeline_integrity_issue_types" => %{
          "type" => "array",
          "items" => %{
            "type" => "string",
            "enum" => capability.timeline_integrity_issue_types
          }
        },
        "selected_timeline_integrity_issues" => %{
          "type" => "array",
          "items" => %{"type" => "object"}
        },
        "selected_missing_dependency_activity_ids" => stable_id_array_schema,
        "selected_missing_dependency_timeline_ids" => stable_id_array_schema,
        "selected_self_dependency_activity_ids" => stable_id_array_schema,
        "selected_self_dependency_timeline_ids" => stable_id_array_schema,
        "selected_duplicate_dependency_activity_ids" => stable_id_array_schema,
        "selected_duplicate_dependency_timeline_ids" => stable_id_array_schema,
        "selected_duplicate_exclusivity_activity_ids" => stable_id_array_schema,
        "selected_duplicate_exclusivity_timeline_ids" => stable_id_array_schema,
        "selected_dependency_cycle_activity_ids" => stable_id_array_schema,
        "selected_dependency_cycle_timeline_ids" => stable_id_array_schema,
        "selected_dependency_order_violation_activity_ids" => stable_id_array_schema,
        "selected_dependency_order_violation_timeline_ids" => stable_id_array_schema,
        "selected_exclusivity_violation_activity_ids" => stable_id_array_schema,
        "selected_exclusivity_violation_timeline_ids" => stable_id_array_schema,
        "selected_exclusivity_violation_group" => %{"type" => "string"},
        "timeline_revision" => OrbitalDynamics.Schema.TimelineRevisionContracts.json_schema(),
        "source_timeline_diff" => Keyword.fetch!(opts, :timeline_diff_row_schema)
      }
    }
  end

  def selected_activity_from_context(deps) when is_list(deps) do
    selected_activity(
      timeline_capability: fetch_dep!(deps, :timeline_capability),
      stable_id_pattern: fetch_dep!(deps, :stable_id_pattern),
      stable_id_array_schema: fetch_dep!(deps, :stable_id_array_schema),
      timeline_identity_schema: fetch_dep!(deps, :timeline_identity_schema),
      activity_context_schema: fetch_dep!(deps, :activity_context_schema)
    )
  end

  def selected_activity_from_context(
        timeline_capability,
        stable_id_pattern,
        stable_id_array_schema,
        timeline_identity_schema,
        activity_context_schema
      ) do
    selected_activity(
      timeline_capability: timeline_capability,
      stable_id_pattern: stable_id_pattern,
      stable_id_array_schema: stable_id_array_schema,
      timeline_identity_schema: timeline_identity_schema,
      activity_context_schema: activity_context_schema
    )
  end

  def selected_activity(opts) do
    capability = Keyword.fetch!(opts, :timeline_capability)
    stable_id_pattern = Keyword.fetch!(opts, :stable_id_pattern)
    stable_id_array_schema = Keyword.fetch!(opts, :stable_id_array_schema)

    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => [
        "activity_id",
        "timeline_id",
        "activity_type",
        "status",
        "approval_status",
        "locked",
        "has_source_window",
        "has_cadence_import",
        "timeline_identity"
      ],
      "properties" => %{
        "activity_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "timeline_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "activity_type" => %{"type" => "string"},
        "status" => %{
          "type" => "string",
          "enum" => capability.activity_statuses
        },
        "approval_status" => %{
          "type" => "string",
          "enum" => capability.approval_statuses
        },
        "locked" => %{"type" => "boolean"},
        "allow_overlap" => %{"type" => "boolean"},
        "operational_kind" => %{
          "type" => "string",
          "enum" => capability.operational_kinds
        },
        "required_operator_action" => %{
          "type" => "string",
          "enum" => capability.required_operator_actions
        },
        "operator_action_reason" => %{"type" => "string"},
        "execution_boundary" => %{
          "type" => "string",
          "enum" => capability.execution_boundaries
        },
        "cadence_import_status" => %{
          "type" => "string",
          "enum" => capability.cadence_import_statuses
        },
        "starts_at_s" => %{"type" => "number"},
        "ends_at_s" => %{"type" => "number"},
        "target_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "command_window_id" => %{"type" => "string"},
        "command_window_type" => %{"type" => "string"},
        "approved" => %{"type" => "boolean"},
        "has_source_window" => %{"type" => "boolean"},
        "has_cadence_import" => %{"type" => "boolean"},
        "timeline_identity" => Keyword.fetch!(opts, :timeline_identity_schema),
        "activity_context" => Keyword.fetch!(opts, :activity_context_schema),
        "protection_decision" => %{"type" => "string"},
        "protection_category" => %{"type" => "string"},
        "protection_reason" => %{"type" => "string"},
        "timeline_integrity_status" => %{"type" => "string"},
        "timeline_integrity_issue_count" => %{"type" => "integer", "minimum" => 0},
        "timeline_integrity_issue_types" => %{
          "type" => "array",
          "items" => %{
            "type" => "string",
            "enum" => capability.timeline_integrity_issue_types
          }
        },
        "timeline_integrity_issues" => %{
          "type" => "array",
          "items" => %{"type" => "object"}
        },
        "missing_dependency_activity_ids" => stable_id_array_schema,
        "missing_dependency_timeline_ids" => stable_id_array_schema,
        "self_dependency_activity_ids" => stable_id_array_schema,
        "self_dependency_timeline_ids" => stable_id_array_schema,
        "duplicate_dependency_activity_ids" => stable_id_array_schema,
        "duplicate_dependency_timeline_ids" => stable_id_array_schema,
        "duplicate_exclusivity_activity_ids" => stable_id_array_schema,
        "duplicate_exclusivity_timeline_ids" => stable_id_array_schema,
        "dependency_cycle_activity_ids" => stable_id_array_schema,
        "dependency_cycle_timeline_ids" => stable_id_array_schema,
        "dependency_order_violation_activity_ids" => stable_id_array_schema,
        "dependency_order_violation_timeline_ids" => stable_id_array_schema,
        "exclusivity_violation_activity_ids" => stable_id_array_schema,
        "exclusivity_violation_timeline_ids" => stable_id_array_schema
      }
    }
  end

  def property("source", _contract_name, _opts) do
    %{"type" => "string"}
  end

  def property("model", @report, _opts) do
    %{"type" => "string", "const" => "artifact_only_timeline_transition_application"}
  end

  def property("schema_contract", @summary, _opts) do
    %{"type" => "string", "const" => @summary}
  end

  def property("model", @summary, _opts) do
    %{"type" => "string", "const" => "artifact_only_timeline_transition_application_summary"}
  end

  def property("validation_level", @summary, _opts) do
    %{"type" => "string", "const" => "artifact_contract"}
  end

  def property("source_artifact_type", @summary, _opts) do
    %{"type" => "string", "const" => @report}
  end

  def property("applications", @report, opts) do
    %{"type" => "array", "items" => Keyword.fetch!(opts, :application_row_schema)}
  end

  def property("selected_activities", @report, opts) do
    %{"type" => "array", "items" => Keyword.fetch!(opts, :selected_activity_schema)}
  end

  def property("timeline_revision", contract_name, _opts)
      when contract_name in [@report, @summary] do
    OrbitalDynamics.Schema.TimelineRevisionContracts.json_schema()
  end

  def property("review_applications", @summary, opts) do
    %{"type" => "array", "items" => Keyword.fetch!(opts, :application_row_schema)}
  end

  def property("model_limits", contract_name, opts) when contract_name in [@report, @summary] do
    model_limits = Keyword.fetch!(opts, :model_limits)

    %{
      "type" => "array",
      "const" => model_limits,
      "items" => %{"type" => "string", "enum" => model_limits}
    }
  end

  def property("selected_timeline_integrity_issue_types", contract_name, opts)
      when contract_name in [@report, @summary] do
    %{
      "type" => "array",
      "items" => %{
        "type" => "string",
        "enum" => Keyword.fetch!(opts, :timeline_capability).timeline_integrity_issue_types
      }
    }
  end

  def property(field, @report, _opts) when field in @report_integer_fields do
    %{"type" => "integer", "minimum" => 0}
  end

  def property(field, @summary, _opts) when field in @summary_integer_fields do
    %{"type" => "integer", "minimum" => 0}
  end

  def property(field, @report, opts) when field in @report_enum_count_fields do
    Keyword.fetch!(opts, :enum_count_map_schema).(
      enum_values(field, Keyword.fetch!(opts, :timeline_capability))
    )
  end

  def property(field, @summary, opts) when field in @summary_enum_count_fields do
    Keyword.fetch!(opts, :enum_count_map_schema).(
      enum_values(field, Keyword.fetch!(opts, :timeline_capability))
    )
  end

  def property(field, @summary, opts) when field in @summary_stable_id_array_fields do
    Keyword.fetch!(opts, :stable_id_array_schema)
  end

  def property(field, @summary, opts) when field in @summary_stable_id_array_map_fields do
    Keyword.fetch!(opts, :stable_id_array_map_schema)
  end

  def property("assumptions", @summary, _opts) do
    %{"type" => "object", "additionalProperties" => true}
  end

  defp enum_values("application_status_counts", capability) do
    capability.transition_application_statuses
  end

  defp enum_values("transition_decision_counts", capability) do
    capability.transition_decisions
  end

  defp enum_values("required_operator_action_counts", capability) do
    capability.transition_decision_required_operator_actions
  end

  defp enum_values("status_transition_counts", capability) do
    capability.lifecycle_transition_types
  end

  defp enum_values("approval_transition_counts", capability) do
    capability.lifecycle_transition_types
  end

  defp enum_values("status_transition_category_counts", capability) do
    capability.status_transition_categories
  end

  defp enum_values("approval_transition_category_counts", capability) do
    capability.approval_transition_categories
  end

  defp fetch_dep!(deps, key) do
    case Keyword.fetch!(deps, key) do
      fun when is_function(fun, 0) -> fun.()
      value -> value
    end
  end
end
