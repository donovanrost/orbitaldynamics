defmodule OrbitalDynamics.Schema.ContactIntentJsonSchema do
  @moduledoc false

  @property_fields [
    "direction",
    "approval_requirements",
    "approval_rule_matches",
    "policy_decision",
    "model_limits",
    "timeline_integrity_issue_count",
    "timeline_integrity_issue_types",
    "timeline_integrity_issues"
  ]

  def property_field?(field), do: field in @property_fields

  def property_from_context(field, deps) when is_list(deps) do
    property(field, property_opts(field, deps))
  end

  def property_fun_from_context(deps) when is_list(deps) do
    fn field ->
      property_from_context(field, deps)
    end
  end

  def property_opts("approval_requirements", deps) do
    [approval_requirement_schema: fetch_dep!(deps, :approval_requirement_schema)]
  end

  def property_opts("approval_rule_matches", deps) do
    [policy_decision_rule_match_schema: fetch_dep!(deps, :policy_decision_rule_match_schema)]
  end

  def property_opts("policy_decision", deps) do
    [policy_decision_schema: fetch_dep!(deps, :policy_decision_schema)]
  end

  def property_opts("model_limits", deps) do
    [model_limits: fetch_dep!(deps, :model_limits)]
  end

  def property_opts("timeline_integrity_issue_types", deps) do
    [timeline_integrity_issue_types: fetch_dep!(deps, :timeline_integrity_issue_types)]
  end

  def property_opts(_field, _deps), do: []

  def row_from_context(
        stable_id_pattern,
        timeline_identity_schema,
        approval_requirement_schema,
        policy_decision_rule_match_schema,
        model_limits,
        policy_decision_schema
      ) do
    row(
      stable_id_pattern: stable_id_pattern,
      timeline_identity_schema: timeline_identity_schema,
      approval_requirement_schema: approval_requirement_schema,
      policy_decision_rule_match_schema: policy_decision_rule_match_schema,
      model_limits: model_limits,
      policy_decision_schema: policy_decision_schema
    )
  end

  def row_from_context(deps) do
    row(
      stable_id_pattern: fetch_dep!(deps, :stable_id_pattern),
      timeline_identity_schema: fetch_dep!(deps, :timeline_identity_schema),
      approval_requirement_schema: fetch_dep!(deps, :approval_requirement_schema),
      policy_decision_rule_match_schema: fetch_dep!(deps, :policy_decision_rule_match_schema),
      model_limits: fetch_dep!(deps, :model_limits),
      policy_decision_schema: fetch_dep!(deps, :policy_decision_schema)
    )
  end

  def row(opts) do
    stable_id_pattern = Keyword.fetch!(opts, :stable_id_pattern)

    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => [
        "schema_contract",
        "id",
        "activity_id",
        "scenario_id",
        "ground_station_id",
        "direction",
        "starts_at_s",
        "ends_at_s"
      ],
      "properties" => %{
        "schema_contract" => %{"type" => "string", "const" => "contact_intent.v1"},
        "id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "activity_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "scenario_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "spacecraft_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "timeline_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "timeline_identity" => Keyword.fetch!(opts, :timeline_identity_schema),
        "ground_station_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "direction" => property("direction", []),
        "starts_at_s" => %{"type" => "number"},
        "ends_at_s" => %{"type" => "number"},
        "activity_type" => %{"type" => "string"},
        "estimated_throughput_mb" => %{"type" => "number"},
        "station_availability" => %{"type" => "string"},
        "capacity_fraction" => %{"type" => "number", "minimum" => 0.0, "maximum" => 1.0},
        "capacity_fraction_min" => %{"type" => "number", "minimum" => 0.0, "maximum" => 1.0},
        "capacity_fraction_max" => %{"type" => "number", "minimum" => 0.0, "maximum" => 1.0},
        "station_contention_status" => %{"type" => "string"},
        "station_reservation_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "station_reservation_expires_at_s" => %{"type" => "number"},
        "station_reserved_by" => %{"type" => "string"},
        "station_reservation_status" => %{"type" => "string"},
        "schedule_conflict_status" => %{"type" => "string"},
        "source_window_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "cadence_import" => %{"type" => "object", "additionalProperties" => true},
        "approval_status" => %{
          "type" => "string",
          "enum" => ["auto_approvable", "operator_review_required", "blocked_by_policy"]
        },
        "approval_requirements" =>
          property(
            "approval_requirements",
            approval_requirement_schema: Keyword.fetch!(opts, :approval_requirement_schema)
          ),
        "approval_rule_matches" =>
          property(
            "approval_rule_matches",
            policy_decision_rule_match_schema:
              Keyword.fetch!(opts, :policy_decision_rule_match_schema)
          ),
        "model_limits" =>
          property(
            "model_limits",
            model_limits: Keyword.fetch!(opts, :model_limits)
          ),
        "policy_decision" =>
          property("policy_decision",
            policy_decision_schema: Keyword.fetch!(opts, :policy_decision_schema)
          )
      }
    }
  end

  def property("direction", _opts) do
    %{
      "type" => "string",
      "enum" => ["downlink", "uplink", "command", "tracking", "health_check"]
    }
  end

  def property("approval_requirements", opts) do
    %{
      "type" => "array",
      "items" => Keyword.fetch!(opts, :approval_requirement_schema)
    }
  end

  def property("approval_rule_matches", opts) do
    %{
      "type" => "array",
      "items" => Keyword.fetch!(opts, :policy_decision_rule_match_schema)
    }
  end

  def property("policy_decision", opts) do
    Keyword.fetch!(opts, :policy_decision_schema)
  end

  def property("model_limits", opts) do
    %{
      "type" => "array",
      "items" => %{"type" => "string", "enum" => Keyword.fetch!(opts, :model_limits)}
    }
  end

  def property("timeline_integrity_issue_count", _opts) do
    %{"type" => "integer", "minimum" => 0}
  end

  def property("timeline_integrity_issue_types", opts) do
    %{
      "type" => "array",
      "items" => %{
        "type" => "string",
        "enum" => Keyword.fetch!(opts, :timeline_integrity_issue_types)
      }
    }
  end

  def property("timeline_integrity_issues", _opts) do
    %{
      "type" => "array",
      "items" => %{
        "type" => "object",
        "additionalProperties" => true,
        "required" => ["issue_type"],
        "properties" => %{"issue_type" => %{"type" => "string"}}
      }
    }
  end

  defp fetch_dep!(deps, key) do
    case Keyword.fetch!(deps, key) do
      value when is_function(value, 0) -> value.()
      value -> value
    end
  end
end
