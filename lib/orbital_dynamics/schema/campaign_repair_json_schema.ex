defmodule OrbitalDynamics.Schema.CampaignRepairJsonSchema do
  @moduledoc false

  @property_fields [
    "activities",
    "source_candidate_activities",
    "deltas",
    "approval_requirements",
    "approval_policy",
    "policy_decision",
    "score_terms",
    "source_candidate_refresh_provenance",
    "source_validation_records",
    "timeline_transition_application_report",
    "warnings"
  ]

  def property_field?(field) when field in @property_fields, do: true
  def property_field?(_field), do: false

  def property_fun_from_context(deps) when is_list(deps) do
    fn field ->
      property(field, property_opts(field, deps))
    end
  end

  def property_opts("activities", deps) do
    [planned_activity_schema: fetch_dep!(deps, :planned_activity_schema)]
  end

  def property_opts("source_candidate_activities", deps) do
    [candidate_activity_schema: fetch_dep!(deps, :candidate_activity_schema)]
  end

  def property_opts("deltas", deps) do
    [plan_delta_schema: fetch_dep!(deps, :plan_delta_schema)]
  end

  def property_opts("approval_requirements", deps) do
    [approval_requirement_schema: fetch_dep!(deps, :approval_requirement_schema)]
  end

  def property_opts("approval_policy", deps) do
    [policy_action_rule_schema: fetch_dep!(deps, :policy_action_rule_schema)]
  end

  def property_opts("policy_decision", deps) do
    [policy_decision_schema: fetch_dep!(deps, :policy_decision_schema)]
  end

  def property_opts("source_candidate_refresh_provenance", deps) do
    [
      candidate_refresh_provenance_schema: fetch_dep!(deps, :candidate_refresh_provenance_schema)
    ]
  end

  def property_opts("source_validation_records", deps) do
    [
      candidate_refresh_validation_records_schema:
        fetch_dep!(deps, :candidate_refresh_validation_records_schema)
    ]
  end

  def property_opts("timeline_transition_application_report", deps) do
    [
      required_fields: fetch_dep!(deps, :timeline_transition_required_fields),
      optional_fields: fetch_dep!(deps, :timeline_transition_optional_fields),
      property_fun: fetch_dep!(deps, :timeline_transition_property_fun)
    ]
  end

  def property_opts(_field, _deps), do: []

  def property("activities", opts) do
    opts
    |> Keyword.fetch!(:planned_activity_schema)
    |> campaign_repair_activity_schema()
    |> array_of()
  end

  def property("source_candidate_activities", opts) do
    array_of(Keyword.fetch!(opts, :candidate_activity_schema))
  end

  def property("deltas", opts) do
    array_of(Keyword.fetch!(opts, :plan_delta_schema))
  end

  def property("approval_requirements", opts) do
    array_of(Keyword.fetch!(opts, :approval_requirement_schema))
  end

  def property("approval_policy", opts) do
    OrbitalDynamics.Schema.PolicyDecisionJsonSchema.approval_policy(
      policy_action_rule_schema: Keyword.fetch!(opts, :policy_action_rule_schema)
    )
  end

  def property("policy_decision", opts) do
    Keyword.fetch!(opts, :policy_decision_schema)
  end

  def property("source_candidate_refresh_provenance", opts) do
    Keyword.fetch!(opts, :candidate_refresh_provenance_schema)
  end

  def property("source_validation_records", opts) do
    Keyword.fetch!(opts, :candidate_refresh_validation_records_schema)
  end

  def property("score_terms", _opts) do
    %{
      "type" => "object",
      "additionalProperties" => %{"type" => "number"}
    }
  end

  def property("timeline_transition_application_report", opts) do
    required_fields = Keyword.fetch!(opts, :required_fields)
    optional_fields = Keyword.fetch!(opts, :optional_fields)
    property_fun = Keyword.fetch!(opts, :property_fun)

    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => required_fields,
      "properties" =>
        (required_fields ++ optional_fields)
        |> Enum.uniq()
        |> Enum.sort()
        |> Map.new(&{&1, property_fun.(&1)})
    }
  end

  def property("warnings", _opts) do
    string_array_schema()
  end

  defp campaign_repair_activity_schema(activity_schema) do
    stable_id_schema = get_in(activity_schema, ["properties", "id"])

    Map.update(activity_schema, "properties", %{}, fn properties ->
      Map.put(properties, "repair", repair_metadata_schema(stable_id_schema))
    end)
  end

  defp repair_metadata_schema(stable_id_schema) do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "properties" => %{
        "replacement_ranking" => replacement_ranking_schema(stable_id_schema)
      }
    }
  end

  defp replacement_ranking_schema(stable_id_schema) do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => [
        "model",
        "selection_scope",
        "selected_candidate_id",
        "evaluated_candidate_count",
        "rows",
        "global_optimization"
      ],
      "properties" => %{
        "model" => %{"const" => "greedy_repair_replacement_ranking"},
        "selection_scope" => %{"const" => "viable_unique_candidates_within_repair_intent"},
        "selected_candidate_id" => stable_id_schema,
        "evaluated_candidate_count" => %{"type" => "integer", "minimum" => 1},
        "rows" => %{
          "type" => "array",
          "minItems" => 1,
          "items" => replacement_ranking_row_schema(stable_id_schema)
        },
        "global_optimization" => %{"const" => false}
      }
    }
  end

  defp replacement_ranking_row_schema(stable_id_schema) do
    number_fields = [
      "candidate_score",
      "schedule_churn_s",
      "schedule_churn_penalty",
      "schedule_move_penalty",
      "station_calendar_pressure_penalty",
      "contact_intent_pressure_penalty",
      "contact_contention_resolution_pressure_penalty",
      "link_capacity_pressure_penalty",
      "resource_projection_pressure_penalty",
      "ranking_score"
    ]

    properties =
      number_fields
      |> Map.new(&{&1, %{"type" => "number"}})
      |> Map.merge(%{
        "rank" => %{"type" => "integer", "minimum" => 1},
        "candidate_id" => stable_id_schema,
        "semantic_candidate_diff_match" => %{"type" => "boolean"},
        "candidate_diff_priority" => %{"type" => "integer", "enum" => [0, 1]},
        "selected" => %{"type" => "boolean"},
        "station_calendar_pressure_sources" => %{
          "type" => "array",
          "minItems" => 1,
          "uniqueItems" => true,
          "items" => %{
            "type" => "string",
            "enum" => [
              "campaign_repair.source_contact_allocation_report.rows",
              "campaign_repair.source_station_calendar_report.affected_contacts"
            ]
          }
        },
        "contact_intent_pressure_statuses" => %{
          "type" => "array",
          "minItems" => 1,
          "uniqueItems" => true,
          "items" => %{
            "type" => "string",
            "enum" => [
              "blocked_by_policy",
              "cadence_import_invalid",
              "cadence_import_missing",
              "invalid_activity_input"
            ]
          }
        },
        "contact_contention_resolution_group_ids" => %{
          "type" => "array",
          "minItems" => 1,
          "uniqueItems" => true,
          "items" => stable_id_schema
        },
        "link_capacity_pressure_shortfall_mb" => %{
          "type" => "number",
          "exclusiveMinimum" => 0
        },
        "resource_projection_pressure_risk_indicators" => %{
          "type" => "array",
          "minItems" => 1,
          "items" => resource_risk_indicator_schema(stable_id_schema)
        }
      })

    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => [
        "rank",
        "candidate_id",
        "semantic_candidate_diff_match",
        "candidate_diff_priority",
        "candidate_score",
        "schedule_churn_s",
        "schedule_churn_penalty",
        "schedule_move_penalty",
        "station_calendar_pressure_penalty",
        "link_capacity_pressure_penalty",
        "resource_projection_pressure_penalty",
        "ranking_score",
        "selected"
      ],
      "properties" => properties
    }
  end

  defp resource_risk_indicator_schema(stable_id_schema) do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => ["type", "severity", "reason", "spacecraft_id"],
      "properties" => %{
        "type" => %{"type" => "string"},
        "severity" => %{"type" => "string"},
        "reason" => %{"type" => "string"},
        "candidate_id" => stable_id_schema,
        "spacecraft_id" => stable_id_schema,
        "resource_pressure_types" => string_array_schema()
      }
    }
  end

  def plan_delta_from_deps(deps) do
    deps
    |> plan_delta_opts()
    |> plan_delta()
  end

  def plan_delta_from_context(
        stable_id_pattern,
        planned_activity_schema,
        realized_activity_schema,
        timeline_link_schema,
        activity_context_schema
      ) do
    [
      stable_id_pattern: stable_id_pattern,
      planned_activity_schema: planned_activity_schema,
      realized_activity_schema: realized_activity_schema,
      timeline_link_schema: timeline_link_schema,
      activity_context_schema: activity_context_schema
    ]
    |> plan_delta_opts()
    |> plan_delta()
  end

  def plan_delta(opts) do
    stable_id_pattern = Keyword.fetch!(opts, :stable_id_pattern)
    planned_activity_schema = Keyword.fetch!(opts, :planned_activity_schema)
    realized_activity_schema = Keyword.fetch!(opts, :realized_activity_schema)
    timeline_link_schema = Keyword.fetch!(opts, :timeline_link_schema)
    activity_context_schema = Keyword.fetch!(opts, :activity_context_schema)

    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => [
        "activity_id",
        "activity_type",
        "status",
        "repair_action"
      ],
      "properties" => %{
        "schema_contract" => %{"type" => "string", "const" => "plan_delta.v1"},
        "activity_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "activity_type" => %{"type" => "string"},
        "status" => %{"type" => "string"},
        "repair_action" => %{"type" => "string"},
        "reason" => %{"type" => "string"},
        "requires_approval" => %{"type" => "boolean"},
        "replacement_activity_id" => %{
          "type" => "string",
          "pattern" => stable_id_pattern
        },
        "source_timeline_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "replacement_timeline_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "planned" => planned_activity_schema,
        "realized" => realized_activity_schema,
        "timeline_link" => timeline_link_schema,
        "source_activity_context" => activity_context_schema,
        "replacement_activity_context" => activity_context_schema
      }
    }
  end

  defp array_of(item_schema) do
    %{
      "type" => "array",
      "items" => item_schema
    }
  end

  defp string_array_schema do
    %{"type" => "array", "items" => %{"type" => "string"}}
  end

  defp fetch_dep!(deps, key) do
    deps
    |> Keyword.fetch!(key)
    |> call_dep()
  end

  defp plan_delta_opts(deps) do
    [
      stable_id_pattern: fetch_dep!(deps, :stable_id_pattern),
      planned_activity_schema: fetch_dep!(deps, :planned_activity_schema),
      realized_activity_schema: fetch_dep!(deps, :realized_activity_schema),
      timeline_link_schema: fetch_dep!(deps, :timeline_link_schema),
      activity_context_schema: fetch_dep!(deps, :activity_context_schema)
    ]
  end

  defp call_dep(dep) when is_function(dep, 0), do: dep.()
  defp call_dep(dep), do: dep
end
