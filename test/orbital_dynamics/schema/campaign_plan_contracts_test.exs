defmodule OrbitalDynamics.Schema.CampaignPlanContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema

  test "exports nested campaign plan activity, contact, and ranked timeline schemas" do
    assert {:ok, schema} = Schema.json_schema("campaign_plan.v1")

    assert get_in(schema, ["properties", "warnings", "items", "type"]) == "string"

    activity_schema = get_in(schema, ["properties", "activities", "items"])

    assert activity_schema["required"] == [
             "id",
             "type",
             "scenario_id",
             "starts_at_s",
             "ends_at_s",
             "duration_s",
             "score",
             "score_terms",
             "source_window_id",
             "source_window"
           ]

    assert get_in(activity_schema, ["properties", "source_window_id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(schema, [
             "properties",
             "candidate_activities",
             "items",
             "properties",
             "score_terms",
             "type"
           ]) == "object"

    contact_schema = get_in(schema, ["properties", "proposed_contacts", "items"])

    assert contact_schema["type"] == "object"

    assert contact_schema["required"] == [
             "id",
             "type",
             "scenario_id",
             "ground_station_id",
             "starts_at_s",
             "ends_at_s",
             "direction",
             "estimated_throughput_mb",
             "source_window",
             "cadence_import"
           ]

    assert get_in(contact_schema, ["properties", "id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(contact_schema, ["properties", "type", "const"]) == "downlink"

    assert get_in(contact_schema, ["properties", "ground_station_id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(contact_schema, ["properties", "direction", "enum"]) == [
             "downlink",
             "uplink",
             "command",
             "tracking"
           ]

    assert get_in(contact_schema, ["properties", "source_window", "type"]) == "object"

    assert get_in(contact_schema, [
             "properties",
             "cadence_import",
             "required"
           ]) == ["external_id", "activity_type"]

    assert get_in(contact_schema, [
             "properties",
             "cadence_import",
             "properties",
             "schema_contract",
             "const"
           ]) == "proposed_contact.v1"

    intent_schema = get_in(schema, ["properties", "contact_intents", "items"])

    assert intent_schema["required"] == [
             "schema_contract",
             "id",
             "activity_id",
             "scenario_id",
             "ground_station_id",
             "direction",
             "starts_at_s",
             "ends_at_s"
           ]

    assert get_in(intent_schema, ["properties", "schema_contract", "const"]) ==
             "contact_intent.v1"

    assert get_in(intent_schema, [
             "properties",
             "approval_rule_matches",
             "items",
             "properties",
             "classification",
             "enum"
           ]) == ["auto_approvable", "operator_review_required", "blocked_by_policy"]

    timeline_schema = get_in(schema, ["properties", "ranked_timelines", "items"])

    assert timeline_schema["required"] == [
             "scenario_id",
             "score",
             "score_terms",
             "activity_count",
             "activities"
           ]

    assert get_in(timeline_schema, ["properties", "scenario_id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(timeline_schema, [
             "properties",
             "activities",
             "items",
             "properties",
             "source_window_id",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]
  end

  test "exports nested campaign repair activity, delta, and approval schemas" do
    assert {:ok, schema} = Schema.json_schema("campaign_repair.v2")

    assert get_in(schema, ["properties", "warnings", "items", "type"]) == "string"

    activity_schema = get_in(schema, ["properties", "activities", "items"])

    assert activity_schema["required"] == [
             "id",
             "scenario_id",
             "starts_at_s",
             "ends_at_s"
           ]

    assert activity_schema["anyOf"] == [
             %{"required" => ["type"]},
             %{"required" => ["activity_type"]}
           ]

    assert get_in(activity_schema, ["properties", "activity_type", "type"]) == "string"

    assert get_in(activity_schema, ["properties", "source_window_id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(schema, [
             "properties",
             "source_candidate_activities",
             "items",
             "properties",
             "source_window_id",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    delta_schema = get_in(schema, ["properties", "deltas", "items"])

    assert delta_schema["required"] == [
             "activity_id",
             "activity_type",
             "status",
             "repair_action"
           ]

    assert get_in(delta_schema, ["properties", "schema_contract", "const"]) == "plan_delta.v1"

    assert get_in(delta_schema, ["properties", "activity_id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(delta_schema, [
             "properties",
             "planned",
             "properties",
             "timeline_identity",
             "type"
           ]) ==
             "object"

    assert {:ok, standalone_delta_schema} = Schema.json_schema("plan_delta.v1")

    assert get_in(standalone_delta_schema, ["properties", "source_timeline_id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(standalone_delta_schema, ["properties", "requires_approval", "type"]) ==
             "boolean"

    assert get_in(standalone_delta_schema, [
             "properties",
             "planned",
             "properties",
             "source_window_id",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(standalone_delta_schema, [
             "properties",
             "realized",
             "properties",
             "completed_fraction",
             "maximum"
           ]) == 1.0

    assert get_in(standalone_delta_schema, [
             "properties",
             "source_activity_context",
             "properties",
             "timeline_identity",
             "type"
           ]) == "object"

    assert get_in(delta_schema, ["properties", "realized", "properties", "status", "enum"]) == [
             "completed",
             "executed",
             "partial",
             "missed",
             "failed",
             "delayed",
             "canceled",
             "cancelled",
             "rejected"
           ]

    requirement_schema = get_in(schema, ["properties", "approval_requirements", "items"])

    assert requirement_schema["required"] == ["activity_id", "activity_type", "action", "reason"]

    assert get_in(requirement_schema, ["properties", "schema_contract", "const"]) ==
             "approval_requirement.v1"

    assert get_in(requirement_schema, ["properties", "requirement_type", "enum"]) ==
             [
               "contact_schedule_change",
               "observation_reassignment",
               "maneuver_timing_change",
               "downstream_window_review",
               "strategic_addition",
               "cancellation",
               "command_review",
               "health_check_review",
               "operator_review"
             ]

    assert get_in(requirement_schema, [
             "properties",
             "approval_rule_matches",
             "items",
             "properties",
             "rule_id",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(schema, ["properties", "objective_tradeoff_report", "type"]) == "object"
    assert get_in(schema, ["properties", "score_term_report", "type"]) == "object"

    assert "objective_tradeoff_report.v1" in get_in(schema, [
             "x-orbital-dynamics",
             "nested_contracts"
           ])

    assert "score_term_report.v1" in get_in(schema, ["x-orbital-dynamics", "nested_contracts"])
    assert "link_capacity_report.v1" in get_in(schema, ["x-orbital-dynamics", "nested_contracts"])
  end
end
