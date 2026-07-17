defmodule OrbitalDynamics.Validation.ReferenceFixtures.PolicyDecisions do
  @moduledoc false

  @fixtures %{
    "fixture.artifact.approval_requirement.v1" => %{
      "id" => "fixture.artifact.approval_requirement.v1",
      "model_id" => "artifact.approval_requirement.v1",
      "reference_case" => "checked-in approval requirement artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/approval_requirement_v1.json",
        "contract" => "approval_requirement.v1"
      },
      "expected" => %{
        "schema_contract" => "approval_requirement.v1",
        "activity_id" => "cmd_repoint",
        "activity_type" => "command",
        "action" => "review_command_contact",
        "policy_classification" => "operator_review_required",
        "policy_bundle_id" => "contact_command_review_v1",
        "required_authority" => "contact_schedule_authority",
        "requirement_type" => "command_review",
        "rule_id" => "command_contact_review",
        "approval_rule_match_count" => 1,
        "policy_decision_classification" => "operator_review_required",
        "policy_decision_escalation_count" => 1,
        "timeline_identity_field_count" => 5,
        "timeline_identity_activity_id" => "cmd_repoint",
        "ground_station_id" => "equator_prime",
        "direction" => "command"
      },
      "tolerances" => %{
        "approval_rule_match_count" => 0,
        "policy_decision_escalation_count" => 0,
        "timeline_identity_field_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external policy validation",
        "checks approval requirement classification, authority routing, policy-decision echo, and timeline identity only"
      ]
    },
    "fixture.artifact.policy_decision.v1" => %{
      "id" => "fixture.artifact.policy_decision.v1",
      "model_id" => "artifact.policy_decision.v1",
      "reference_case" => "checked-in policy decision artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/policy_decision_v1.json",
        "contract" => "policy_decision.v1"
      },
      "expected" => %{
        "schema_contract" => "policy_decision.v1",
        "classification" => "operator_review_required",
        "policy_bundle_id" => "mission_ops_escalation_v1",
        "approval_requirement_count" => 1,
        "risk_count" => 0,
        "rule_match_count" => 1,
        "escalation_count" => 1,
        "first_rule_id" => "contact_execution_coordination",
        "first_required_authority" => "contact_schedule_authority",
        "first_escalation_queue" => "ground_network",
        "first_escalation_role" => "contact_scheduler",
        "first_escalation_sla_s" => 1800,
        "boundary" => "artifact_only_no_authority_lookup",
        "workflow_execution" => "none",
        "no_command_execution" => true,
        "no_schedule_mutation" => true,
        "model_limit_count" => 5
      },
      "tolerances" => %{
        "approval_requirement_count" => 0,
        "risk_count" => 0,
        "rule_match_count" => 0,
        "escalation_count" => 0,
        "first_escalation_sla_s" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external policy validation",
        "checks policy decision classification, escalation routing, authority boundary, and model-limit evidence only"
      ]
    }
  }

  def all, do: @fixtures
end
