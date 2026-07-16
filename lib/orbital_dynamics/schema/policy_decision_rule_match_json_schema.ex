defmodule OrbitalDynamics.Schema.PolicyDecisionRuleMatchJsonSchema do
  @moduledoc false

  alias OrbitalDynamics.Policy
  alias OrbitalDynamics.Schema.CommonJsonSchema
  alias OrbitalDynamics.Schema.PolicyContextJsonSchema

  @policy_classifications ["auto_approvable", "operator_review_required", "blocked_by_policy"]

  def rule_match_from_context(opts) when is_list(opts) do
    rule_match_from_context(
      Keyword.fetch!(opts, :stable_id_pattern),
      Keyword.fetch!(opts, :policy_context_fields)
    )
  end

  def rule_match_from_context(stable_id_pattern, policy_context_fields) do
    rule_match(%{
      policy_context_properties:
        policy_context_fields
        |> PolicyContextJsonSchema.properties(),
      stable_id_pattern: stable_id_pattern,
      cadence_import_statuses: Policy.capabilities().cadence_import_statuses
    })
  end

  def escalation_from_context(opts) when is_list(opts) do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> escalation_for_stable_id()
  end

  def escalation_from_context(stable_id_pattern) when is_binary(stable_id_pattern) do
    escalation_for_stable_id(stable_id_pattern)
  end

  def escalation_for_stable_id(stable_id_pattern) do
    escalation(%{stable_id_pattern: stable_id_pattern})
  end

  def rule_match(opts) do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "properties" =>
        opts.policy_context_properties
        |> Map.merge(escalation(opts)["properties"])
        |> Map.merge(rule_match_properties(opts))
    }
  end

  def escalation(opts) do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "properties" => %{
        "rule_id" => %{"type" => "string", "pattern" => opts.stable_id_pattern},
        "classification" => %{
          "type" => "string",
          "enum" => @policy_classifications
        },
        "escalation_level" => %{"type" => "string"},
        "escalation_queue" => %{"type" => "string"},
        "escalation_role" => %{"type" => "string"},
        "required_authority" => %{"type" => "string"},
        "sla_s" => %{"type" => "number"}
      }
    }
  end

  defp rule_match_properties(opts) do
    %{
      "rule_id" => %{"type" => "string", "pattern" => opts.stable_id_pattern},
      "classification" => %{
        "type" => "string",
        "enum" => @policy_classifications
      },
      "reason" => %{"type" => "string"},
      "action" => %{"type" => "string"},
      "activity_id" => %{"type" => "string", "pattern" => opts.stable_id_pattern},
      "activity_type" => %{"type" => "string"},
      "requirement_type" => %{"type" => "string"},
      "direction" => %{"type" => "string"},
      "ground_station_id" => %{"type" => "string"},
      "station_contention_status" => %{"type" => "string"},
      "station_reservation_status" => %{"type" => "string"},
      "station_calendar_reservation_expires_at_s" => CommonJsonSchema.number_array(),
      "contention_window_s" => %{"type" => "number"},
      "total_contact_duration_s" => %{"type" => "number"},
      "overlap_duration_s" => %{"type" => "number"},
      "max_concurrent_contacts" => %{"type" => "integer", "minimum" => 0},
      "overlap_contact_pair_count" => %{"type" => "integer", "minimum" => 0},
      "status" => %{"type" => "string"},
      "approval_status" => %{"type" => "string"},
      "locked" => %{"type" => "boolean"},
      "degraded" => %{"type" => "boolean"},
      "payload_available" => %{"type" => "boolean"},
      "risk_type" => %{"type" => "string"},
      "risk_reason" => %{"type" => "string"},
      "event_type" => %{"type" => "string"},
      "feasibility_status" => %{"type" => "string"},
      "allocation_status" => %{"type" => "string"},
      "effective_allocation_status" => %{"type" => "string"},
      "allocation_reason" => %{"type" => "string"},
      "policy_classification" => %{
        "type" => "string",
        "enum" => @policy_classifications
      },
      "transition_decision" => %{"type" => "string"},
      "application_status" => %{"type" => "string"},
      "planned_protection_decision" => %{"type" => "string"},
      "planned_protection_category" => %{"type" => "string"},
      "timeline_integrity_status" => %{"type" => "string"},
      "timeline_integrity_issue_types" => CommonJsonSchema.string_array(),
      "required_operator_action" => %{"type" => "string"},
      "operator_action_reason" => %{"type" => "string"},
      "contact_result" => %{"type" => "string"},
      "contact_results" => CommonJsonSchema.string_array(),
      "command_result" => %{"type" => "string"},
      "command_results" => CommonJsonSchema.string_array(),
      "observation_result" => %{"type" => "string"},
      "observation_results" => CommonJsonSchema.string_array(),
      "maneuver_result" => %{"type" => "string"},
      "maneuver_results" => CommonJsonSchema.string_array(),
      "priority_fields_without_numeric_evidence_count" => %{
        "type" => "integer",
        "minimum" => 0
      },
      "priority_fields_without_numeric_evidence" => CommonJsonSchema.string_array(),
      "source_timeline_integrity_status" => %{"type" => "string"},
      "source_timeline_integrity_issue_types" => CommonJsonSchema.string_array(),
      "replacement_timeline_integrity_status" => %{"type" => "string"},
      "replacement_timeline_integrity_issue_types" => CommonJsonSchema.string_array(),
      "source_protection_decision" => %{"type" => "string"},
      "replacement_protection_category" => %{"type" => "string"},
      "cadence_import_status" => %{
        "type" => "string",
        "enum" => opts.cadence_import_statuses
      },
      "cadence_import_statuses" => %{
        "type" => "array",
        "items" => %{
          "type" => "string",
          "enum" => opts.cadence_import_statuses
        }
      }
    }
  end
end
