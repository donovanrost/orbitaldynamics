defmodule OrbitalDynamics.Validation.ReferenceFixtures.PolicyBundleArtifacts do
  @moduledoc false

  @fixtures %{
    "fixture.artifact.policy_bundle.v1" => %{
      "id" => "fixture.artifact.policy_bundle.v1",
      "model_id" => "artifact.policy_bundle.v1",
      "reference_case" => "checked-in mission operations policy bundle artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/policy_bundle_v1.json",
        "contract" => "policy_bundle.v1"
      },
      "expected" => %{
        "schema_contract" => "policy_bundle.v1",
        "id" => "mission_ops_escalation_v1",
        "action_rule_count" => 6,
        "blocked_risk_type_count" => 2,
        "auto_approvable_approval_count_limit" => 0,
        "auto_approvable_risk_limit" => 0,
        "operator_review_risk_limit" => 2,
        "classification_counts" => %{
          "blocked_by_policy" => 1,
          "operator_review_required" => 5
        },
        "required_authority_counts" => %{
          "command_authority" => 1,
          "contact_schedule_authority" => 3,
          "flight_director" => 1,
          "mission_planning_authority" => 1
        },
        "boundary" => "artifact_only_no_authority_lookup",
        "workflow_execution" => "none",
        "provenance_source" => "OrbitalDynamics.Policy.bundle!",
        "no_command_execution" => true,
        "no_schedule_mutation" => true,
        "model_limit_count" => 5
      },
      "tolerances" => %{
        "action_rule_count" => 0,
        "blocked_risk_type_count" => 0,
        "auto_approvable_approval_count_limit" => 0,
        "auto_approvable_risk_limit" => 0,
        "operator_review_risk_limit" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external policy validation",
        "checks representative policy bundle rule counts, authority routing maps, artifact-only boundary, and model-limit evidence only"
      ]
    },
    "fixture.artifact.policy_bundle.ground_network_allocation" => %{
      "id" => "fixture.artifact.policy_bundle.ground_network_allocation",
      "model_id" => "artifact.policy_bundle.v1",
      "reference_case" => "checked-in ground-network allocation policy bundle artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/policy_bundle_ground_network_allocation_v1.json",
        "contract" => "policy_bundle.v1"
      },
      "expected" => %{
        "schema_contract" => "policy_bundle.v1",
        "id" => "ground_network_allocation_v1",
        "action_rule_count" => 14,
        "blocked_risk_type_count" => 2,
        "auto_approvable_approval_count_limit" => 0,
        "auto_approvable_risk_limit" => 0,
        "operator_review_risk_limit" => 2,
        "classification_counts" => %{
          "blocked_by_policy" => 3,
          "operator_review_required" => 11
        },
        "required_authority_counts" => %{"contact_schedule_authority" => 14},
        "escalation_queue_counts" => %{
          "ground_network" => 13,
          "ground_network_priority" => 1
        },
        "station_availability_rule_count" => 3,
        "reduced_capacity_rule_count" => 2,
        "unavailable_or_maintenance_rule_count" => 1,
        "contention_rule_count" => 5,
        "contact_allocation_rule_count" => 1,
        "required_operator_action_rule_count" => 2,
        "command_direction_rule_count" => 1,
        "missing_trust_rule_count" => 1,
        "rule_ids_by_classification" => %{
          "blocked_by_policy" => [
            "duplicate_contact_identity_block",
            "reduced_station_capacity_insufficient_block",
            "unavailable_station_contact_block"
          ],
          "operator_review_required" => [
            "command_station_calendar_direction_review",
            "declared_provider_calendar_contention_review",
            "high_overlap_contact_contention_review",
            "invalid_contact_contention_input_review",
            "invalid_link_capacity_input_review",
            "low_actual_downlink_completion_review",
            "missing_priority_field_evidence_review",
            "missing_station_calendar_trust_review",
            "reserved_station_contact_review",
            "same_station_contact_contention_review",
            "severe_capacity_reduction_review"
          ]
        },
        "boundary" => "artifact_only_no_authority_lookup",
        "workflow_execution" => "none",
        "provenance_source" => "OrbitalDynamics.Policy.bundle!",
        "no_command_execution" => true,
        "no_schedule_mutation" => true,
        "model_limit_count" => 5
      },
      "tolerances" => %{
        "action_rule_count" => 0,
        "blocked_risk_type_count" => 0,
        "auto_approvable_approval_count_limit" => 0,
        "auto_approvable_risk_limit" => 0,
        "operator_review_risk_limit" => 0,
        "station_availability_rule_count" => 0,
        "reduced_capacity_rule_count" => 0,
        "unavailable_or_maintenance_rule_count" => 0,
        "contention_rule_count" => 0,
        "contact_allocation_rule_count" => 0,
        "required_operator_action_rule_count" => 0,
        "command_direction_rule_count" => 0,
        "missing_trust_rule_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external policy validation",
        "checks ground-network allocation policy rule counts, authority routing, calendar-review triggers, and artifact-only boundary only"
      ]
    }
  }

  def all, do: @fixtures
end
