defmodule OrbitalDynamics.Schema.OperationalTimelineReportJsonSchema do
  @moduledoc false

  alias OrbitalDynamics.Schema.CommonJsonSchema

  def row_from_context(
        capability,
        stable_id_pattern,
        stable_id_array_schema,
        string_array_schema,
        number_array_schema,
        timeline_precondition_schema,
        activity_context_schema,
        timeline_integrity_issue_schema
      ) do
    row(
      capability: capability,
      stable_id_pattern: stable_id_pattern,
      stable_id_array_schema: stable_id_array_schema,
      string_array_schema: string_array_schema,
      number_array_schema: number_array_schema,
      timeline_precondition_schema: timeline_precondition_schema,
      activity_context_schema: activity_context_schema,
      timeline_integrity_issue_schema: timeline_integrity_issue_schema
    )
  end

  def row_from_context(deps) when is_list(deps) do
    row(
      capability: fetch_dep!(deps, :capability),
      stable_id_pattern: fetch_dep!(deps, :stable_id_pattern),
      stable_id_array_schema: fetch_dep!(deps, :stable_id_array_schema),
      string_array_schema: fetch_dep!(deps, :string_array_schema),
      number_array_schema: fetch_dep!(deps, :number_array_schema),
      timeline_precondition_schema: fetch_dep!(deps, :timeline_precondition_schema),
      activity_context_schema: fetch_dep!(deps, :activity_context_schema),
      timeline_integrity_issue_schema: fetch_dep!(deps, :timeline_integrity_issue_schema)
    )
  end

  def row(opts) do
    capability = Keyword.fetch!(opts, :capability)
    stable_id_pattern = Keyword.fetch!(opts, :stable_id_pattern)
    stable_id_array_schema = Keyword.fetch!(opts, :stable_id_array_schema)
    string_array_schema = Keyword.fetch!(opts, :string_array_schema)
    number_array_schema = Keyword.fetch!(opts, :number_array_schema)
    timeline_precondition_schema = Keyword.fetch!(opts, :timeline_precondition_schema)
    activity_context_schema = Keyword.fetch!(opts, :activity_context_schema)
    timeline_integrity_issue_schema = Keyword.fetch!(opts, :timeline_integrity_issue_schema)

    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => [
        "id",
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
        "id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "activity_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "timeline_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "scenario_id" => %{"type" => "string", "pattern" => stable_id_pattern},
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
        "precondition_status" => %{
          "type" => "string",
          "enum" => capability.activity_precondition_statuses
        },
        "blocked_precondition_count" => %{"type" => "integer", "minimum" => 0},
        "review_precondition_count" => %{"type" => "integer", "minimum" => 0},
        "blocked_precondition_types" => string_array_schema,
        "review_precondition_types" => string_array_schema,
        "preconditions" => %{
          "type" => "array",
          "items" => timeline_precondition_schema
        },
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
        "setup_duration_s" => %{"type" => "number", "minimum" => 0.0},
        "cooldown_duration_s" => %{"type" => "number", "minimum" => 0.0},
        "telemetry_confirmation_required" => %{"type" => "boolean"},
        "telemetry_confirmation_status" => %{"type" => "string"},
        "direction" => %{"type" => "string"},
        "command_window_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "command_window_type" => %{"type" => "string"},
        "command_authority_status" => %{"type" => "string"},
        "required_authority" => %{"type" => "string"},
        "command_safety_status" => %{"type" => "string"},
        "command_authorized" => %{"type" => "boolean"},
        "command_safety_checked" => %{"type" => "boolean"},
        "ground_station_id" => %{"type" => "string"},
        "target_id" => %{"type" => "string"},
        "attitude_mode" => %{"type" => "string"},
        "attitude_target_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "roll_deg" => %{"type" => "number"},
        "pitch_deg" => %{"type" => "number"},
        "yaw_deg" => %{"type" => "number"},
        "attitude_error_deg" => %{"type" => "number"},
        "attitude_status" => %{"type" => "string"},
        "attitude_model" => %{"type" => "string"},
        "attitude_source" => %{"type" => "string"},
        "attitude_confidence" => %{"type" => "number", "minimum" => 0.0, "maximum" => 1.0},
        "station_availability" => %{"type" => "string"},
        "schedule_conflict_status" => %{"type" => "string"},
        "source_window_id" => %{"type" => "string"},
        "source_window_type" => %{"type" => "string"},
        "cadence_import_type" => %{"type" => "string"},
        "station_calendar_entry_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "station_calendar_provider_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "station_calendar_provider_entry_id" => %{
          "type" => "string",
          "pattern" => stable_id_pattern
        },
        "station_calendar_directions" => string_array_schema,
        "station_calendar_status" => %{"type" => "string"},
        "station_calendar_overlap_count" => %{"type" => "integer", "minimum" => 0},
        "station_calendar_overlap_entry_ids" => stable_id_array_schema,
        "station_calendar_overlap_availabilities" => string_array_schema,
        "station_calendar_entry_ambiguous" => %{"type" => "boolean"},
        "station_calendar_ambiguous_entry_count" => %{"type" => "integer", "minimum" => 0},
        "station_calendar_ambiguous_entry_ids" => stable_id_array_schema,
        "station_calendar_reservation_overlap_count" => %{"type" => "integer", "minimum" => 0},
        "station_calendar_reservation_ids" => stable_id_array_schema,
        "station_calendar_reserved_by" => string_array_schema,
        "station_calendar_reservation_statuses" => string_array_schema,
        "station_calendar_reservation_expires_at_s" => number_array_schema,
        "station_calendar_trust_boundary_status" => %{"type" => "string"},
        "station_contention_status" => %{"type" => "string"},
        "station_reservation_match_status" => %{"type" => "string"},
        "station_reservation_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "station_reservation_expires_at_s" => %{"type" => "number"},
        "station_reserved_by" => %{"type" => "string"},
        "station_reservation_status" => %{"type" => "string"},
        "source_station_calendar_entry" => %{"type" => "object", "additionalProperties" => true},
        "source_station_calendar_overlaps" => %{
          "type" => "array",
          "items" => %{"type" => "object", "additionalProperties" => true}
        },
        "activity_context" => activity_context_schema,
        "dependency_activity_ids" => stable_id_array_schema,
        "dependency_order_violation_activity_ids" => stable_id_array_schema,
        "missing_dependency_activity_ids" => stable_id_array_schema,
        "self_dependency_activity_ids" => stable_id_array_schema,
        "self_dependency_timeline_ids" => stable_id_array_schema,
        "duplicate_dependency_activity_ids" => stable_id_array_schema,
        "duplicate_dependency_timeline_ids" => stable_id_array_schema,
        "duplicate_exclusivity_activity_ids" => stable_id_array_schema,
        "duplicate_exclusivity_timeline_ids" => stable_id_array_schema,
        "exclusive_with_activity_ids" => stable_id_array_schema,
        "exclusivity_group" => %{"type" => "string"},
        "exclusivity_violation_activity_ids" => stable_id_array_schema,
        "exclusivity_violation_group" => %{"type" => "string"},
        "exclusivity_violation_timeline_ids" => stable_id_array_schema,
        "superseded_required_operator_action" => %{"type" => "string"},
        "superseded_operator_action_reason" => %{"type" => "string"},
        "timeline_integrity_status" => %{"type" => "string"},
        "timeline_integrity_issue_count" => %{"type" => "integer"},
        "timeline_integrity_issue_types" => %{
          "type" => "array",
          "items" => %{
            "type" => "string",
            "enum" => capability.timeline_integrity_issue_types
          }
        },
        "timeline_integrity_issues" => %{
          "type" => "array",
          "items" => timeline_integrity_issue_schema
        },
        "has_source_window" => %{"type" => "boolean"},
        "has_cadence_import" => %{"type" => "boolean"},
        "timeline_identity" => %{
          "type" => "object",
          "additionalProperties" => true,
          "properties" => %{
            "timeline_id" => %{"type" => "string", "pattern" => stable_id_pattern},
            "activity_id" => %{"type" => "string", "pattern" => stable_id_pattern},
            "activity_type" => %{"type" => "string"},
            "scenario_id" => %{"type" => "string", "pattern" => stable_id_pattern},
            "subject_id" => %{"type" => "string"},
            "source_window_id" => %{"type" => "string"}
          }
        }
      }
    }
  end

  def integrity_issue_from_context(deps) when is_list(deps) do
    integrity_issue(
      capability: fetch_dep!(deps, :capability),
      stable_id_pattern: fetch_dep!(deps, :stable_id_pattern)
    )
  end

  def integrity_issue(opts) do
    stable_id_pattern = Keyword.fetch!(opts, :stable_id_pattern)
    capability = Keyword.fetch!(opts, :capability)

    issue_evidence_properties =
      [
        "missing_dependency_activity_id",
        "missing_dependency_timeline_id",
        "self_dependency_activity_id",
        "self_dependency_timeline_id",
        "duplicate_dependency_activity_id",
        "duplicate_dependency_timeline_id",
        "duplicate_exclusivity_activity_id",
        "duplicate_exclusivity_timeline_id",
        "dependency_activity_id",
        "dependency_timeline_id",
        "dependency_order_violation_activity_id",
        "dependency_order_violation_timeline_id",
        "exclusivity_violation_activity_id",
        "exclusivity_violation_timeline_id"
      ]
      |> Map.new(&{&1, %{"type" => "string", "pattern" => stable_id_pattern}})

    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => ["type"],
      "properties" =>
        Map.merge(issue_evidence_properties, %{
          "type" => %{
            "type" => "string",
            "enum" => capability.timeline_integrity_issue_types
          },
          "exclusivity_violation_group" => %{"type" => "string"}
        })
    }
  end

  @stable_id_array_fields [
    "invalid_activity_input_ids",
    "duplicate_dependency_activity_ids",
    "duplicate_dependency_timeline_ids",
    "duplicate_exclusivity_activity_ids",
    "duplicate_exclusivity_timeline_ids"
  ]

  @integer_fields [
    "activity_count",
    "row_count",
    "contact_count",
    "command_count",
    "locked_count",
    "approved_count",
    "executed_count",
    "source_window_lineage_count",
    "valid_activity_count",
    "invalid_activity_input_count",
    "terminal_exception_count",
    "execution_uncertainty_declared_count",
    "execution_uncertainty_missing_count",
    "dependency_count",
    "dependency_issue_count",
    "exclusivity_count",
    "exclusivity_issue_count",
    "timeline_integrity_review_count",
    "timeline_integrity_issue_count",
    "duplicate_timeline_identity_count",
    "duplicate_timeline_identity_activity_count"
  ]

  @enum_count_map_fields [
    "activity_status_counts",
    "approval_status_counts",
    "required_operator_action_counts",
    "cadence_import_status_counts",
    "operational_kind_counts"
  ]

  def property_field?(field)
      when field in [
             "rows",
             "source",
             "model",
             "model_limits"
           ],
      do: true

  def property_field?(field)
      when field in @stable_id_array_fields or field in @integer_fields or
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

  def property("rows", opts) do
    %{"type" => "array", "items" => Keyword.fetch!(opts, :row_schema)}
  end

  def property("source", _opts), do: %{"type" => "string"}

  def property("model", _opts) do
    %{"type" => "string", "const" => "selected_activity_operational_context_summary"}
  end

  def property("model_limits", opts) do
    model_limits = Keyword.fetch!(opts, :model_limits)

    %{
      "type" => "array",
      "const" => model_limits,
      "items" => %{"type" => "string", "enum" => model_limits}
    }
  end

  def property(field, opts) when field in @stable_id_array_fields do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> CommonJsonSchema.stable_id_array()
  end

  def property(field, _opts) when field in @integer_fields do
    %{"type" => "integer", "minimum" => 0}
  end

  def property(field, opts)
      when field in [
             "activity_status_counts",
             "approval_status_counts",
             "required_operator_action_counts",
             "cadence_import_status_counts",
             "operational_kind_counts"
           ] do
    opts
    |> Keyword.fetch!(:capability)
    |> capability_values(field)
    |> CommonJsonSchema.enum_count_map()
  end

  defp capability_values(capability, "activity_status_counts"), do: capability.activity_statuses
  defp capability_values(capability, "approval_status_counts"), do: capability.approval_statuses

  defp capability_values(capability, "required_operator_action_counts"),
    do: capability.required_operator_actions

  defp capability_values(capability, "cadence_import_status_counts"),
    do: capability.cadence_import_statuses

  defp capability_values(capability, "operational_kind_counts"), do: capability.operational_kinds

  defp fetch_dep!(deps, key) do
    case Keyword.fetch!(deps, key) do
      fun when is_function(fun, 0) -> fun.()
      value -> value
    end
  end
end
