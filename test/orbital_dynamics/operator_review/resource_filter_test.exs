defmodule OrbitalDynamics.OperatorReview.ResourceFilterTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{OperatorReview, Schema}

  test "builds review package from standalone resource filter report suppressions" do
    report = %{
      "schema_contract" => "resource_filter_report.v1",
      "id" => "resource_filter:mission_state",
      "model" => "resource_summary_availability_and_margin_filter",
      "input_candidate_count" => 2,
      "kept_candidate_count" => 1,
      "suppressed_candidate_count" => 1,
      "suppressed_candidates" => [
        %{
          "id" => "leo_1_observe_target_a_1",
          "type" => "observe",
          "scenario_id" => "leo_1",
          "spacecraft_id" => "sat_payload",
          "starts_at_s" => 60.0,
          "ends_at_s" => 180.0,
          "suppressed_reason" => "payload_unavailable",
          "source_window_id" => "window:leo_1:target_visibility:target_a:1",
          "payload_available" => false,
          "approval_status" => "blocked_by_policy",
          "approval_requirements" => [
            %{
              "activity_id" => "leo_1_observe_target_a_1",
              "activity_type" => "observe",
              "action" => "review_suppressed_observation",
              "requirement_type" => "observation_reassignment",
              "reason" => "payload_unavailable"
            }
          ],
          "approval_rule_matches" => [
            %{"rule_id" => "payload_unavailable_observation_block"}
          ],
          "policy_decision" => %{
            "schema_contract" => "policy_decision.v1",
            "policy_bundle_id" => "degraded_payload_guard_v1",
            "escalations" => [
              %{"rule_id" => "unmatched_resource_rule", "escalation_queue" => "ignore_queue"},
              %{
                "rule_id" => "payload_unavailable_observation_block",
                "required_authority" => "payload_operations_authority",
                "escalation_level" => "payload_lead",
                "escalation_queue" => "payload_ops",
                "escalation_role" => "payload_scheduler",
                "sla_s" => 900
              }
            ]
          }
        }
      ],
      "provenance" => %{"source" => "test"}
    }

    package = OperatorReview.from_resource_filter_report(report)

    assert OrbitalDynamics.operator_review_package(report) == package

    assert %{
             "source_artifact_type" => "resource_filter_report.v1",
             "source_artifact_id" => "resource_filter:mission_state",
             "review_count" => 1,
             "resource_suppression_count" => 1
           } = package

    assert %{
             "review_type" => "resource_suppression",
             "source" => "resource_filter_report.suppressed_candidates",
             "activity_id" => "leo_1_observe_target_a_1",
             "required_operator_action" => "review_suppressed_observation",
             "approval_status" => "blocked_by_policy",
             "spacecraft_id" => "sat_payload",
             "payload_available" => false,
             "requirement_type" => "observation_reassignment",
             "required_authority" => "payload_operations_authority",
             "policy_bundle_id" => "degraded_payload_guard_v1",
             "rule_id" => "payload_unavailable_observation_block",
             "escalation_level" => "payload_lead",
             "escalation_queue" => "payload_ops",
             "escalation_role" => "payload_scheduler",
             "sla_s" => 900,
             "approval_rule_matches" => [
               %{"rule_id" => "payload_unavailable_observation_block"}
             ],
             "source_policy_decision" => %{
               "policy_bundle_id" => "degraded_payload_guard_v1"
             },
             "source_policy_escalation" => %{
               "rule_id" => "payload_unavailable_observation_block",
               "escalation_queue" => "payload_ops"
             },
             "source_resource_suppression" => %{"suppressed_reason" => "payload_unavailable"}
           } = List.first(package["rows"])

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    invalid_package =
      update_in(package, ["rows"], fn [row] ->
        [Map.put(row, "payload_available", true)]
      end)

    assert {:error, report} = Schema.validate_artifact(invalid_package)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].payload_available" and
                 &1["message"] == "must match source_resource_suppression.payload_available")
           )
  end

  test "routes planned-contact downlink resource suppressions through contact review actions" do
    report = %{
      "schema_contract" => "resource_filter_report.v1",
      "id" => "resource_filter:planned_contacts",
      "model" => "resource_summary_availability_and_margin_filter",
      "input_candidate_count" => 1,
      "kept_candidate_count" => 0,
      "suppressed_candidate_count" => 1,
      "suppressed_candidates" => [
        %{
          "id" => "planned_downlink_1",
          "type" => "planned_contact",
          "direction" => "downlink",
          "scenario_id" => "leo_1",
          "spacecraft_id" => "sat_1",
          "ground_station_id" => "equator_prime",
          "suppressed_reason" => "antenna_unavailable",
          "antenna_available" => false
        }
      ]
    }

    package = OperatorReview.from_resource_filter_report(report)

    assert [
             %{
               "review_type" => "resource_suppression",
               "activity_id" => "planned_downlink_1",
               "activity_type" => "planned_contact",
               "direction" => "downlink",
               "action" => "review_suppressed_contact",
               "required_operator_action" => "review_suppressed_contact",
               "antenna_available" => false
             }
           ] = package["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "resource filter report source ids fall back through defaults" do
    assert %{"source_artifact_id" => "resource-filter:report"} =
             OperatorReview.from_resource_filter_report(%{
               id: :"resource-filter:report",
               suppressed_candidates: []
             })

    assert %{"source_artifact_id" => "resource-filter:source"} =
             OperatorReview.from_resource_filter_report(%{
               source: :"resource-filter:source",
               suppressed_candidates: []
             })

    assert %{"source_artifact_id" => "resource_filter_report"} =
             OperatorReview.from_resource_filter_report(%{suppressed_candidates: []})
  end
end
