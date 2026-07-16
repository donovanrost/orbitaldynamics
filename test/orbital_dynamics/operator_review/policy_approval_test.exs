defmodule OrbitalDynamics.OperatorReview.PolicyApprovalTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{OperatorReview, Policy, Schema}

  test "policy decision source ids fall back through defaults" do
    assert %{"source_artifact_id" => "policy:decision"} =
             OperatorReview.from_policy_decision(%{id: :"policy:decision"})

    assert %{"source_artifact_id" => "policy:bundle"} =
             OperatorReview.from_policy_decision(%{policy_bundle_id: :"policy:bundle"})

    assert %{"source_artifact_id" => "policy_decision"} =
             OperatorReview.from_policy_decision(%{})
  end

  test "approval requirement source ids fall back through defaults" do
    assert %{"source_artifact_id" => "approval:requirement"} =
             OperatorReview.from_approval_requirement(%{id: :"approval:requirement"})

    assert %{"source_artifact_id" => "activity:approval"} =
             OperatorReview.from_approval_requirement(%{activity_id: :"activity:approval"})

    assert %{"source_artifact_id" => "approval_requirement"} =
             OperatorReview.from_approval_requirement(%{})
  end

  test "builds review package from standalone policy decision escalations" do
    decision = %{
      "schema_contract" => "policy_decision.v1",
      "classification" => "operator_review_required",
      "model_limits" => Policy.capabilities().known_limits |> Enum.map(&to_string/1),
      "policy_bundle_id" => "mission_ops_escalation_v1",
      "policy_bundle_provenance" => %{
        "source" => "organization_policy_adapter",
        "adapter" => "example_policy_adapter",
        "organization_id" => "mission_ops",
        "policy_source" => "operator_config",
        "trust_boundary" => "organization_policy_adapter"
      },
      "approval_requirement_count" => 1,
      "risk_count" => 0,
      "rule_matches" => [],
      "escalations" => [
        %{
          "rule_id" => "contact_execution_coordination",
          "classification" => "operator_review_required",
          "escalation_level" => "ops_lead",
          "escalation_queue" => "ground_network",
          "escalation_role" => "contact_scheduler",
          "required_authority" => "contact_schedule_authority",
          "sla_s" => 1800
        }
      ],
      "provenance" => %{"source" => "test"}
    }

    package = OperatorReview.from_policy_decision(decision)

    assert OrbitalDynamics.operator_review_package(decision) == package

    assert %{
             "source_artifact_type" => "policy_decision.v1",
             "source_artifact_id" => "mission_ops_escalation_v1",
             "review_count" => 1,
             "policy_escalation_count" => 1
           } = package

    assert %{
             "review_type" => "policy_escalation",
             "source" => "policy_decision.escalations",
             "subject_id" => "contact_execution_coordination",
             "required_operator_action" => "review_policy_escalation",
             "approval_status" => "operator_review_required",
             "policy_bundle_id" => "mission_ops_escalation_v1",
             "policy_bundle_provenance" => %{
               "source" => "organization_policy_adapter",
               "adapter" => "example_policy_adapter",
               "organization_id" => "mission_ops",
               "policy_source" => "operator_config",
               "trust_boundary" => "organization_policy_adapter"
             },
             "policy_bundle_provenance_source" => "organization_policy_adapter",
             "policy_bundle_adapter" => "example_policy_adapter",
             "policy_bundle_organization_id" => "mission_ops",
             "policy_bundle_policy_source" => "operator_config",
             "required_authority" => "contact_schedule_authority",
             "source_policy_decision" => %{
               "schema_contract" => "policy_decision.v1",
               "model_limits" => [
                 "artifact_classification_only",
                 "no_command_execution",
                 "no_schedule_mutation",
                 "no_external_authority_lookup",
                 "no_multi_step_workflow_execution"
               ],
               "policy_bundle_provenance" => %{
                 "source" => "organization_policy_adapter",
                 "adapter" => "example_policy_adapter",
                 "trust_boundary" => "organization_policy_adapter"
               }
             }
           } = List.first(package["rows"])

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "builds review package from standalone approval requirement" do
    requirement = %{
      "schema_contract" => "approval_requirement.v1",
      "activity_id" => "dl_2",
      "activity_type" => "downlink",
      "action" => "approve_moved_contact",
      "requirement_type" => "contact_schedule_change",
      "required_authority" => "contact_schedule_authority",
      "policy_bundle_id" => "ground_network_allocation_v1",
      "approval_rule_matches" => [
        %{"rule_id" => "moved_contact_schedule_review"}
      ],
      "policy_decision" => %{
        "schema_contract" => "policy_decision.v1",
        "classification" => "operator_review_required",
        "policy_bundle_id" => "ground_network_allocation_v1",
        "escalations" => [
          %{"rule_id" => "unmatched_rule", "escalation_queue" => "ignore_queue"},
          %{
            "rule_id" => "moved_contact_schedule_review",
            "escalation_level" => "ops_lead",
            "escalation_queue" => "ground_network",
            "escalation_role" => "network_scheduler",
            "required_authority" => "network_ops_lead",
            "sla_s" => 900
          }
        ]
      },
      "reason" => "missed_contact_rescheduled",
      "policy_classification" => "operator_review_required",
      "provenance" => %{"source" => "test"}
    }

    package = OperatorReview.from_approval_requirement(requirement)

    assert OrbitalDynamics.operator_review_package(requirement) == package

    assert %{
             "source_artifact_type" => "approval_requirement.v1",
             "source_artifact_id" => "dl_2",
             "review_count" => 1,
             "approval_requirement_count" => 1
           } = package

    assert %{
             "review_type" => "approval_requirement",
             "source" => "approval_requirement",
             "subject_id" => "dl_2",
             "required_operator_action" => "approve_moved_contact",
             "approval_status" => "operator_review_required",
             "requirement_type" => "contact_schedule_change",
             "required_authority" => "contact_schedule_authority",
             "policy_bundle_id" => "ground_network_allocation_v1",
             "rule_id" => "moved_contact_schedule_review",
             "escalation_level" => "ops_lead",
             "escalation_queue" => "ground_network",
             "escalation_role" => "network_scheduler",
             "sla_s" => 900,
             "approval_rule_matches" => [
               %{"rule_id" => "moved_contact_schedule_review"}
             ],
             "source_policy_escalation" => %{
               "rule_id" => "moved_contact_schedule_review",
               "escalation_queue" => "ground_network"
             },
             "source_requirement" => %{"schema_contract" => "approval_requirement.v1"}
           } = List.first(package["rows"])

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    stale_source_requirement =
      update_in(package, ["rows"], fn [row] ->
        [
          row
          |> put_in(["source_requirement", "activity_id"], "stale_dl")
          |> put_in(["source_requirement", "action"], "stale_action")
        ]
      end)

    assert {:error, stale_source_requirement_report} =
             Schema.validate_artifact(stale_source_requirement)

    assert Enum.any?(
             stale_source_requirement_report["errors"],
             &(&1["path"] == "$.rows[0].activity_id" and
                 &1["message"] == "must match source_requirement.activity_id")
           )

    assert Enum.any?(
             stale_source_requirement_report["errors"],
             &(&1["path"] == "$.rows[0].required_operator_action" and
                 &1["message"] == "must match source_requirement.action")
           )
  end
end
