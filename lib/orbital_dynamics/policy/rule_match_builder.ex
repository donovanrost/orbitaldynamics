defmodule OrbitalDynamics.Policy.RuleMatchBuilder do
  @moduledoc false

  alias OrbitalDynamics.Policy.{
    ActivityMatcher,
    EventMatcher,
    RequirementContext,
    RequirementMatcher,
    RiskMatcher
  }

  def build(
        rule,
        approval_requirements,
        risk_indicators,
        branch,
        candidate_plan,
        escalation_fields
      ) do
    requirement_matches =
      approval_requirements
      |> Enum.filter(&RequirementMatcher.match?(rule, &1))
      |> Enum.map(fn requirement ->
        %{
          "rule_id" => rule["id"],
          "classification" => rule["classification"],
          "reason" => rule["reason"],
          "action" => requirement["action"],
          "activity_id" => requirement["activity_id"],
          "activity_type" => requirement["activity_type"],
          "requirement_type" => requirement["requirement_type"],
          "spacecraft_id" => RequirementContext.value(requirement, "spacecraft_id"),
          "spacecraft_ids" =>
            non_empty_list(RequirementContext.values(requirement, "spacecraft_id")),
          "target_id" => RequirementContext.value(requirement, "target_id"),
          "target_ids" => non_empty_list(RequirementContext.values(requirement, "target_id")),
          "direction" => List.first(RequirementContext.values(requirement, "direction")),
          "directions" => non_empty_list(RequirementContext.values(requirement, "direction")),
          "ground_station_id" => RequirementContext.value(requirement, "ground_station_id"),
          "ground_station_ids" =>
            non_empty_list(RequirementContext.values(requirement, "ground_station_id")),
          "station_availability" => RequirementContext.value(requirement, "station_availability"),
          "station_availabilities" =>
            non_empty_list(RequirementContext.values(requirement, "station_availability")),
          "capacity_fraction" => RequirementContext.value(requirement, "capacity_fraction"),
          "required_capacity_fraction" =>
            RequirementContext.value(requirement, "required_capacity_fraction"),
          "actual_completion_fraction" =>
            RequirementContext.value(requirement, "actual_completion_fraction"),
          "station_contention_status" =>
            RequirementContext.value(requirement, "station_contention_status"),
          "station_contention_statuses" =>
            non_empty_list(RequirementContext.values(requirement, "station_contention_status")),
          "station_reservation_id" =>
            RequirementContext.value(requirement, "station_reservation_id"),
          "station_reservation_ids" =>
            non_empty_list(RequirementContext.values(requirement, "station_reservation_id")),
          "station_reserved_by" => RequirementContext.value(requirement, "station_reserved_by"),
          "station_reserved_bys" =>
            non_empty_list(RequirementContext.values(requirement, "station_reserved_by")),
          "station_reservation_status" =>
            RequirementContext.value(requirement, "station_reservation_status"),
          "station_reservation_statuses" =>
            non_empty_list(RequirementContext.values(requirement, "station_reservation_status")),
          "station_reservation_match_status" =>
            RequirementContext.value(requirement, "station_reservation_match_status"),
          "station_reservation_match_statuses" =>
            non_empty_list(
              RequirementContext.values(requirement, "station_reservation_match_status")
            ),
          "station_calendar_entry_id" =>
            RequirementContext.value(requirement, "station_calendar_entry_id"),
          "station_calendar_entry_ids" =>
            non_empty_list(RequirementContext.values(requirement, "station_calendar_entry_id")),
          "station_calendar_reserved_by" =>
            non_empty_list(RequirementContext.values(requirement, "station_calendar_reserved_by")),
          "station_calendar_reserved_bys" =>
            non_empty_list(RequirementContext.values(requirement, "station_calendar_reserved_by")),
          "station_calendar_reservation_status" =>
            RequirementContext.value(requirement, "station_calendar_reservation_status") ||
              List.first(
                RequirementContext.values(requirement, "station_calendar_reservation_status")
              ),
          "station_calendar_reservation_statuses" =>
            non_empty_list(
              RequirementContext.values(requirement, "station_calendar_reservation_status")
            ),
          "station_calendar_reservation_expires_at_s" =>
            non_empty_list(
              RequirementContext.values(requirement, "station_calendar_reservation_expires_at_s")
            ),
          "station_calendar_status" =>
            RequirementContext.value(requirement, "station_calendar_status"),
          "station_calendar_statuses" =>
            non_empty_list(RequirementContext.values(requirement, "station_calendar_status")),
          "station_calendar_entry_ambiguous" =>
            RequirementContext.value(requirement, "station_calendar_entry_ambiguous"),
          "station_calendar_ambiguous_entry_count" =>
            RequirementContext.value(requirement, "station_calendar_ambiguous_entry_count"),
          "contention_window_s" => RequirementContext.value(requirement, "contention_window_s"),
          "total_contact_duration_s" =>
            RequirementContext.value(requirement, "total_contact_duration_s"),
          "overlap_duration_s" => RequirementContext.value(requirement, "overlap_duration_s"),
          "max_concurrent_contacts" =>
            RequirementContext.value(requirement, "max_concurrent_contacts"),
          "overlap_contact_pair_count" =>
            RequirementContext.value(requirement, "overlap_contact_pair_count"),
          "station_calendar_ambiguous_entry_ids" =>
            non_empty_list(
              RequirementContext.values(requirement, "station_calendar_ambiguous_entry_id")
            ),
          "station_calendar_trust_boundary_status" =>
            RequirementContext.value(requirement, "station_calendar_trust_boundary_status"),
          "station_calendar_trust_boundary_statuses" =>
            non_empty_list(
              RequirementContext.values(requirement, "station_calendar_trust_boundary_status")
            ),
          "station_calendar_direction" =>
            List.first(RequirementContext.values(requirement, "station_calendar_direction")),
          "station_calendar_directions" =>
            non_empty_list(RequirementContext.values(requirement, "station_calendar_direction")),
          "resource_scope" => RequirementContext.value(requirement, "resource_scope"),
          "resource_scopes" =>
            non_empty_list(RequirementContext.values(requirement, "resource_scope")),
          "selection_reason" => RequirementContext.value(requirement, "selection_reason"),
          "selection_reasons" =>
            non_empty_list(RequirementContext.values(requirement, "selection_reason")),
          "selected_priority_source" =>
            RequirementContext.value(requirement, "selected_priority_source"),
          "selected_priority_sources" =>
            non_empty_list(RequirementContext.values(requirement, "selected_priority_source")),
          "priority_fields_without_numeric_evidence_count" =>
            RequirementContext.value(
              requirement,
              "priority_fields_without_numeric_evidence_count"
            ),
          "priority_fields_without_numeric_evidence" =>
            non_empty_list(
              RequirementContext.values(requirement, "priority_fields_without_numeric_evidence")
            ),
          "resolution_status" => RequirementContext.value(requirement, "resolution_status"),
          "resolution_statuses" =>
            non_empty_list(RequirementContext.values(requirement, "resolution_status")),
          "resolution_issue" => RequirementContext.value(requirement, "resolution_issue"),
          "resolution_issues" =>
            non_empty_list(RequirementContext.values(requirement, "resolution_issue")),
          "station_calendar_provider_ids" =>
            non_empty_list(RequirementContext.values(requirement, "station_calendar_provider_id")),
          "station_calendar_provider_entry_ids" =>
            non_empty_list(
              RequirementContext.values(requirement, "station_calendar_provider_entry_id")
            ),
          "station_calendar_reservation_id" =>
            RequirementContext.value(requirement, "station_calendar_reservation_id") ||
              List.first(
                RequirementContext.values(requirement, "station_calendar_reservation_id")
              ),
          "station_calendar_reservation_ids" =>
            non_empty_list(
              RequirementContext.values(requirement, "station_calendar_reservation_id")
            ),
          "required_operator_action" =>
            RequirementContext.value(requirement, "required_operator_action"),
          "required_operator_actions" =>
            non_empty_list(RequirementContext.values(requirement, "required_operator_action")),
          "operator_action_reason" =>
            RequirementContext.value(requirement, "operator_action_reason"),
          "operator_action_reasons" =>
            non_empty_list(RequirementContext.values(requirement, "operator_action_reason")),
          "allocation_status" => RequirementContext.value(requirement, "allocation_status"),
          "allocation_statuses" =>
            non_empty_list(RequirementContext.values(requirement, "allocation_status")),
          "effective_allocation_status" =>
            RequirementContext.value(requirement, "effective_allocation_status"),
          "effective_allocation_statuses" =>
            non_empty_list(RequirementContext.values(requirement, "effective_allocation_status")),
          "allocation_reason" => RequirementContext.value(requirement, "allocation_reason"),
          "allocation_reasons" =>
            non_empty_list(RequirementContext.values(requirement, "allocation_reason")),
          "suppressed_reason" => RequirementContext.value(requirement, "suppressed_reason"),
          "suppressed_reasons" =>
            non_empty_list(RequirementContext.values(requirement, "suppressed_reason")),
          "resource_blocking_dimension" =>
            RequirementContext.value(requirement, "resource_blocking_dimension"),
          "resource_blocking_dimensions" =>
            non_empty_list(RequirementContext.values(requirement, "resource_blocking_dimension")),
          "transition_decision" => RequirementContext.value(requirement, "transition_decision"),
          "transition_decisions" =>
            non_empty_list(RequirementContext.values(requirement, "transition_decision")),
          "application_status" => RequirementContext.value(requirement, "application_status"),
          "application_statuses" =>
            non_empty_list(RequirementContext.values(requirement, "application_status")),
          "planned_protection_decision" =>
            RequirementContext.value(requirement, "planned_protection_decision"),
          "planned_protection_decisions" =>
            non_empty_list(RequirementContext.values(requirement, "planned_protection_decision")),
          "planned_protection_category" =>
            RequirementContext.value(requirement, "planned_protection_category"),
          "planned_protection_categories" =>
            non_empty_list(RequirementContext.values(requirement, "planned_protection_category")),
          "timeline_integrity_status" =>
            RequirementContext.value(requirement, "timeline_integrity_status"),
          "timeline_integrity_statuses" =>
            non_empty_list(RequirementContext.values(requirement, "timeline_integrity_status")),
          "timeline_integrity_issue_types" =>
            non_empty_list(
              RequirementContext.values(requirement, "timeline_integrity_issue_types")
            ),
          "source_timeline_integrity_status" =>
            RequirementContext.value(requirement, "source_timeline_integrity_status"),
          "source_timeline_integrity_statuses" =>
            non_empty_list(
              RequirementContext.values(requirement, "source_timeline_integrity_status")
            ),
          "source_timeline_integrity_issue_types" =>
            non_empty_list(
              RequirementContext.values(requirement, "source_timeline_integrity_issue_types")
            ),
          "replacement_timeline_integrity_status" =>
            RequirementContext.value(requirement, "replacement_timeline_integrity_status"),
          "replacement_timeline_integrity_statuses" =>
            non_empty_list(
              RequirementContext.values(requirement, "replacement_timeline_integrity_status")
            ),
          "replacement_timeline_integrity_issue_types" =>
            non_empty_list(
              RequirementContext.values(
                requirement,
                "replacement_timeline_integrity_issue_types"
              )
            ),
          "source_protection_decision" =>
            RequirementContext.value(requirement, "source_protection_decision"),
          "source_protection_decisions" =>
            non_empty_list(RequirementContext.values(requirement, "source_protection_decision")),
          "source_protection_category" =>
            RequirementContext.value(requirement, "source_protection_category"),
          "source_protection_categories" =>
            non_empty_list(RequirementContext.values(requirement, "source_protection_category")),
          "replacement_protection_decision" =>
            RequirementContext.value(requirement, "replacement_protection_decision"),
          "replacement_protection_decisions" =>
            non_empty_list(
              RequirementContext.values(requirement, "replacement_protection_decision")
            ),
          "replacement_protection_category" =>
            RequirementContext.value(requirement, "replacement_protection_category"),
          "replacement_protection_categories" =>
            non_empty_list(
              RequirementContext.values(requirement, "replacement_protection_category")
            ),
          "review_queue" => RequirementContext.value(requirement, "review_queue"),
          "review_queues" =>
            non_empty_list(RequirementContext.values(requirement, "review_queue")),
          "review_queue_key" => RequirementContext.value(requirement, "review_queue_key"),
          "review_queue_keys" =>
            non_empty_list(RequirementContext.values(requirement, "review_queue_key")),
          "cadence_import_status" =>
            RequirementContext.value(requirement, "cadence_import_status"),
          "cadence_import_statuses" =>
            non_empty_list(RequirementContext.values(requirement, "cadence_import_status")),
          "status" => RequirementContext.value(requirement, "status"),
          "statuses" => non_empty_list(RequirementContext.values(requirement, "status")),
          "approval_status" => RequirementContext.value(requirement, "approval_status"),
          "approval_statuses" =>
            non_empty_list(RequirementContext.values(requirement, "approval_status")),
          "policy_classification" =>
            RequirementContext.value(requirement, "policy_classification"),
          "policy_classifications" =>
            non_empty_list(RequirementContext.values(requirement, "policy_classification")),
          "locked" => RequirementContext.value(requirement, "locked"),
          "degraded" => RequirementContext.value(requirement, "degraded"),
          "payload_available" => RequirementContext.value(requirement, "payload_available"),
          "antenna_available" => RequirementContext.value(requirement, "antenna_available"),
          "contact_success" => RequirementContext.value(requirement, "contact_success"),
          "contact_success_factor" =>
            RequirementContext.value(requirement, "contact_success_factor"),
          "contact_success_factor_source" =>
            RequirementContext.value(requirement, "contact_success_factor_source"),
          "contact_result" =>
            RequirementContext.provider_result_context_value(requirement, "contact_result"),
          "contact_results" =>
            non_empty_list(RequirementContext.values(requirement, "contact_result")),
          "command_success" => RequirementContext.value(requirement, "command_success"),
          "command_success_factor" =>
            RequirementContext.value(requirement, "command_success_factor"),
          "command_success_factor_source" =>
            RequirementContext.value(requirement, "command_success_factor_source"),
          "command_result" =>
            RequirementContext.provider_result_context_value(requirement, "command_result"),
          "command_results" =>
            non_empty_list(RequirementContext.values(requirement, "command_result")),
          "observation_success_factor" =>
            RequirementContext.value(requirement, "observation_success_factor"),
          "observation_success_factor_source" =>
            RequirementContext.value(requirement, "observation_success_factor_source"),
          "observation_result" =>
            RequirementContext.provider_result_context_value(requirement, "observation_result"),
          "observation_results" =>
            non_empty_list(RequirementContext.values(requirement, "observation_result")),
          "maneuver_success_factor" =>
            RequirementContext.value(requirement, "maneuver_success_factor"),
          "maneuver_success_factor_source" =>
            RequirementContext.value(requirement, "maneuver_success_factor_source"),
          "maneuver_result" =>
            RequirementContext.provider_result_context_value(requirement, "maneuver_result"),
          "maneuver_results" =>
            non_empty_list(RequirementContext.values(requirement, "maneuver_result")),
          "resource_pressure_status" =>
            RequirementContext.value(requirement, "resource_pressure_status"),
          "resource_pressure_statuses" =>
            non_empty_list(RequirementContext.values(requirement, "resource_pressure_status")),
          "resource_pressure_types" =>
            non_empty_list(RequirementContext.values(requirement, "resource_pressure_types")),
          "resource_source_quality" =>
            RequirementContext.value(requirement, "resource_source_quality"),
          "resource_source_qualities" =>
            non_empty_list(RequirementContext.values(requirement, "resource_source_quality")),
          "resource_trust_boundary" =>
            RequirementContext.value(requirement, "resource_trust_boundary"),
          "resource_trust_boundaries" =>
            non_empty_list(RequirementContext.values(requirement, "resource_trust_boundary")),
          "resource_trust_boundary_status" =>
            RequirementContext.value(requirement, "resource_trust_boundary_status"),
          "resource_trust_boundary_statuses" =>
            non_empty_list(
              RequirementContext.values(requirement, "resource_trust_boundary_status")
            ),
          "first_resource_pressure_kind" =>
            RequirementContext.value(requirement, "first_resource_pressure_kind"),
          "first_resource_pressure_kinds" =>
            non_empty_list(RequirementContext.values(requirement, "first_resource_pressure_kind")),
          "feedback_source" => RequirementContext.value(requirement, "feedback_source"),
          "feedback_sources" =>
            non_empty_list(RequirementContext.values(requirement, "feedback_source")),
          "feedback_scope" => RequirementContext.value(requirement, "feedback_scope"),
          "feedback_scopes" =>
            non_empty_list(RequirementContext.values(requirement, "feedback_scope")),
          "trust_boundary" => RequirementContext.value(requirement, "trust_boundary"),
          "trust_boundaries" =>
            non_empty_list(RequirementContext.values(requirement, "trust_boundary")),
          "source_event_type" => RequirementContext.value(requirement, "source_event_type"),
          "source_event_types" =>
            non_empty_list(RequirementContext.values(requirement, "source_event_type"))
        }
        |> add_rule_escalation_fields(rule, escalation_fields)
        |> Enum.reject(fn {_key, value} -> is_nil(value) end)
        |> Map.new()
      end)

    risk_matches =
      risk_indicators
      |> Enum.filter(&RiskMatcher.match?(rule, &1))
      |> Enum.map(fn risk ->
        %{
          "rule_id" => rule["id"],
          "classification" => rule["classification"],
          "reason" => rule["reason"],
          "risk_type" => risk["type"],
          "risk_reason" => risk["reason"],
          "ground_station_id" => RiskMatcher.ground_station_id(risk),
          "spacecraft_id" => RiskMatcher.spacecraft_id(risk),
          "target_id" => risk["target_id"],
          "station_availability" => RiskMatcher.context_value(risk, "station_availability"),
          "station_contention_status" =>
            RiskMatcher.context_value(risk, "station_contention_status"),
          "station_calendar_entry_id" =>
            RiskMatcher.context_value(risk, "station_calendar_entry_id"),
          "station_calendar_entry_ids" =>
            non_empty_list(RiskMatcher.context_values(risk, "station_calendar_entry_id")),
          "station_calendar_provider_id" =>
            RiskMatcher.context_value(risk, "station_calendar_provider_id"),
          "station_calendar_provider_ids" =>
            non_empty_list(RiskMatcher.context_values(risk, "station_calendar_provider_id")),
          "station_calendar_provider_entry_id" =>
            RiskMatcher.context_value(risk, "station_calendar_provider_entry_id"),
          "station_calendar_provider_entry_ids" =>
            non_empty_list(RiskMatcher.context_values(risk, "station_calendar_provider_entry_id")),
          "station_calendar_direction" =>
            List.first(RiskMatcher.context_values(risk, "station_calendar_direction")),
          "station_calendar_directions" =>
            non_empty_list(RiskMatcher.context_values(risk, "station_calendar_direction")),
          "station_calendar_status" => RiskMatcher.context_value(risk, "station_calendar_status"),
          "station_calendar_statuses" =>
            non_empty_list(RiskMatcher.context_values(risk, "station_calendar_status")),
          "station_calendar_trust_boundary_status" =>
            RiskMatcher.context_value(risk, "station_calendar_trust_boundary_status"),
          "station_calendar_trust_boundary_statuses" =>
            non_empty_list(
              RiskMatcher.context_values(risk, "station_calendar_trust_boundary_status")
            ),
          "station_calendar_reservation_id" =>
            RiskMatcher.context_value(risk, "station_calendar_reservation_id"),
          "station_calendar_reservation_ids" =>
            non_empty_list(RiskMatcher.context_values(risk, "station_calendar_reservation_id")),
          "station_calendar_reserved_by" =>
            List.first(RiskMatcher.context_values(risk, "station_calendar_reserved_by")),
          "station_calendar_reserved_bys" =>
            non_empty_list(RiskMatcher.context_values(risk, "station_calendar_reserved_by")),
          "station_calendar_reservation_status" =>
            RiskMatcher.context_value(risk, "station_calendar_reservation_status"),
          "station_calendar_reservation_statuses" =>
            non_empty_list(
              RiskMatcher.context_values(risk, "station_calendar_reservation_status")
            ),
          "station_calendar_reservation_expires_at_s" =>
            non_empty_list(
              RiskMatcher.context_values(risk, "station_calendar_reservation_expires_at_s")
            ),
          "station_reservation_id" => RiskMatcher.context_value(risk, "station_reservation_id"),
          "station_reserved_by" => RiskMatcher.context_value(risk, "station_reserved_by"),
          "station_reserved_bys" =>
            non_empty_list(RiskMatcher.context_values(risk, "station_reserved_by")),
          "station_reservation_status" =>
            RiskMatcher.context_value(risk, "station_reservation_status"),
          "station_reservation_statuses" =>
            non_empty_list(RiskMatcher.context_values(risk, "station_reservation_status")),
          "station_reservation_match_status" =>
            RiskMatcher.context_value(risk, "station_reservation_match_status"),
          "station_reservation_match_statuses" =>
            non_empty_list(RiskMatcher.context_values(risk, "station_reservation_match_status")),
          "direction" => RiskMatcher.direction(risk),
          "directions" => non_empty_list(RiskMatcher.directions(risk))
        }
        |> add_rule_escalation_fields(rule, escalation_fields)
        |> Enum.reject(fn {_key, value} -> is_nil(value) end)
        |> Map.new()
      end)

    event_matches =
      branch["events"]
      |> Enum.filter(&EventMatcher.match?(rule, &1))
      |> Enum.map(fn event ->
        %{
          "rule_id" => rule["id"],
          "classification" => rule["classification"],
          "reason" => rule["reason"],
          "event_type" => event["type"],
          "ground_station_id" => EventMatcher.ground_station_id(event),
          "spacecraft_id" => EventMatcher.spacecraft_id(event),
          "target_id" => event["target_id"],
          "activity_id" => event["activity_id"],
          "status" => event["status"],
          "approval_status" => event["approval_status"],
          "policy_classification" => event["policy_classification"],
          "allocation_status" => event["allocation_status"],
          "effective_allocation_status" => event["effective_allocation_status"],
          "allocation_reason" => event["allocation_reason"],
          "direction" => EventMatcher.direction(event),
          "directions" => non_empty_list(EventMatcher.directions(event)),
          "station_calendar_entry_id" => event["station_calendar_entry_id"],
          "station_calendar_entry_ids" =>
            non_empty_list(EventMatcher.context_values(event, "station_calendar_entry_id")),
          "station_calendar_provider_id" => event["station_calendar_provider_id"],
          "station_calendar_provider_ids" =>
            non_empty_list(EventMatcher.context_values(event, "station_calendar_provider_id")),
          "station_calendar_provider_entry_id" => event["station_calendar_provider_entry_id"],
          "station_calendar_provider_entry_ids" =>
            non_empty_list(
              EventMatcher.context_values(event, "station_calendar_provider_entry_id")
            ),
          "station_calendar_direction" =>
            List.first(EventMatcher.context_values(event, "station_calendar_direction")),
          "station_calendar_directions" =>
            non_empty_list(EventMatcher.context_values(event, "station_calendar_direction")),
          "station_calendar_status" => event["station_calendar_status"],
          "station_calendar_statuses" =>
            non_empty_list(EventMatcher.context_values(event, "station_calendar_status")),
          "station_calendar_trust_boundary_status" =>
            event["station_calendar_trust_boundary_status"],
          "station_calendar_trust_boundary_statuses" =>
            non_empty_list(
              EventMatcher.context_values(event, "station_calendar_trust_boundary_status")
            ),
          "station_calendar_reservation_id" =>
            List.first(EventMatcher.context_values(event, "station_calendar_reservation_id")),
          "station_calendar_reservation_ids" =>
            non_empty_list(EventMatcher.context_values(event, "station_calendar_reservation_id")),
          "station_calendar_reserved_by" =>
            List.first(EventMatcher.context_values(event, "station_calendar_reserved_by")),
          "station_calendar_reserved_bys" =>
            non_empty_list(EventMatcher.context_values(event, "station_calendar_reserved_by")),
          "station_calendar_reservation_status" =>
            List.first(EventMatcher.context_values(event, "station_calendar_reservation_status")),
          "station_calendar_reservation_statuses" =>
            non_empty_list(
              EventMatcher.context_values(event, "station_calendar_reservation_status")
            ),
          "station_calendar_reservation_expires_at_s" =>
            non_empty_list(
              EventMatcher.context_values(event, "station_calendar_reservation_expires_at_s")
            ),
          "station_reservation_id" => event["station_reservation_id"] || event["reservation_id"],
          "station_reserved_by" => event["station_reserved_by"] || event["reserved_by"],
          "station_reservation_status" =>
            event["station_reservation_status"] || event["reservation_status"],
          "station_reservation_match_status" => event["station_reservation_match_status"],
          "feedback_source" => event["feedback_source"],
          "feedback_scope" => event["feedback_scope"],
          "trust_boundary" => event["trust_boundary"],
          "source_event_type" => event["type"]
        }
        |> add_rule_escalation_fields(rule, escalation_fields)
        |> Enum.reject(fn {_key, value} -> is_nil(value) end)
        |> Map.new()
      end)

    feasibility_matches =
      candidate_plan
      |> Map.get("strategic_additions", [])
      |> Enum.filter(&ActivityMatcher.match?(rule, &1))
      |> Enum.map(fn activity ->
        %{
          "rule_id" => rule["id"],
          "classification" => rule["classification"],
          "reason" => rule["reason"],
          "activity_id" => activity["id"],
          "activity_type" => activity["type"],
          "ground_station_id" => ActivityMatcher.ground_station_id(activity),
          "spacecraft_id" => ActivityMatcher.spacecraft_id(activity),
          "target_id" => ActivityMatcher.target_id(activity),
          "direction" => ActivityMatcher.direction(activity),
          "directions" => non_empty_list(ActivityMatcher.directions(activity)),
          "feasibility_status" => get_in(activity, ["feasibility", "status"]),
          "feedback_source" => ActivityMatcher.provenance_value(activity, "feedback_source"),
          "feedback_scope" => ActivityMatcher.provenance_value(activity, "feedback_scope"),
          "trust_boundary" => ActivityMatcher.provenance_value(activity, "trust_boundary"),
          "source_event_type" => ActivityMatcher.provenance_value(activity, "source_event_type")
        }
        |> add_rule_escalation_fields(rule, escalation_fields)
        |> Enum.reject(fn {_key, value} -> is_nil(value) end)
        |> Map.new()
      end)

    requirement_matches ++ risk_matches ++ event_matches ++ feasibility_matches
  end

  defp add_rule_escalation_fields(match, rule, escalation_fields) do
    Enum.reduce(escalation_fields, match, fn field, acc ->
      case Map.fetch(rule, field) do
        {:ok, value} -> Map.put(acc, field, value)
        :error -> acc
      end
    end)
  end

  def non_empty_list([]), do: nil
  def non_empty_list(values), do: values
end
