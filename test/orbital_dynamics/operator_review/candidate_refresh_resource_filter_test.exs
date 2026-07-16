defmodule OrbitalDynamics.OperatorReview.CandidateRefreshResourceFilterTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{OperatorReview, Schema}

  test "candidate refresh source resource filter reports become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:resource_filter_review:001",
      "source_resource_filter_report" => %{
        "schema_contract" => "resource_filter_report.v1",
        "id" => "source_resource_filter:mission_state",
        "model" => "resource_summary_availability_and_margin_filter",
        "invalid_resource_summary_inputs" => [
          %{
            "resource_summary_id" => "resource_summary:stale_sat",
            "spacecraft_id" => "sat_1",
            "invalid_resource_summary_input_reason" => "missing_resource_summary_epoch",
            "approval_status" => "operator_review_required",
            "approval_requirements" => [
              %{
                "activity_id" => "resource_summary:stale_sat",
                "activity_type" => "resource_summary",
                "action" => "review_invalid_resource_filter_summary",
                "requirement_type" => "resource_filter_input_validation"
              }
            ],
            "policy_decision" => %{
              "schema_contract" => "policy_decision.v1",
              "policy_bundle_id" => "resource_filter_input_guard_v1"
            },
            "source_resource_summary" => %{"resource_summary_id" => "resource_summary:stale_sat"}
          }
        ],
        "suppressed_candidates" => [
          %{
            "id" => "obs_payload_blocked",
            "type" => "observe",
            "scenario_id" => "leo_1",
            "spacecraft_id" => "sat_1",
            "target_id" => "target_a",
            "starts_at_s" => 60.0,
            "ends_at_s" => 180.0,
            "suppressed_reason" => "payload_unavailable",
            "source_window_id" => "window:leo_1:target_visibility:target_a:1",
            "payload_available" => false,
            "resource_blocking_dimension" => "payload",
            "resource_trust_boundary_status" => "declared",
            "resource_trust_boundary" => "mission_state_resource_summary",
            "approval_status" => "blocked_by_policy",
            "approval_requirements" => [
              %{
                "activity_id" => "obs_payload_blocked",
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
                %{
                  "rule_id" => "payload_unavailable_observation_block",
                  "required_authority" => "payload_operations_authority",
                  "escalation_level" => "payload_lead",
                  "escalation_queue" => "payload_ops",
                  "escalation_role" => "payload_scheduler",
                  "sla_s" => 900
                }
              ]
            },
            "source_resource_summary" => %{"spacecraft_id" => "sat_1"}
          }
        ]
      }
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:resource_filter_review:001",
             "review_count" => 2,
             "resource_suppression_count" => 2
           } = package

    assert %{
             "review_type" => "resource_suppression",
             "source" =>
               "candidate_refresh.source_resource_filter_report.invalid_resource_summary_inputs",
             "subject_id" => "resource_summary:stale_sat",
             "spacecraft_id" => "sat_1",
             "required_operator_action" => "review_invalid_resource_filter_summary",
             "invalid_resource_summary_input" => true,
             "invalid_resource_summary_input_reason" => "missing_resource_summary_epoch",
             "policy_bundle_id" => "resource_filter_input_guard_v1",
             "source_resource_summary" => %{
               "resource_summary_id" => "resource_summary:stale_sat"
             },
             "source_resource_suppression" => %{
               "resource_summary_id" => "resource_summary:stale_sat"
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["required_operator_action"] == "review_invalid_resource_filter_summary")
             )

    assert %{
             "review_type" => "resource_suppression",
             "source" => "candidate_refresh.source_resource_filter_report.suppressed_candidates",
             "subject_id" => "obs_payload_blocked",
             "activity_id" => "obs_payload_blocked",
             "activity_type" => "observe",
             "required_operator_action" => "review_suppressed_observation",
             "approval_status" => "blocked_by_policy",
             "spacecraft_id" => "sat_1",
             "target_id" => "target_a",
             "payload_available" => false,
             "resource_blocking_dimension" => "payload",
             "resource_trust_boundary_status" => "declared",
             "resource_trust_boundary" => "mission_state_resource_summary",
             "requirement_type" => "observation_reassignment",
             "required_authority" => "payload_operations_authority",
             "policy_bundle_id" => "degraded_payload_guard_v1",
             "rule_id" => "payload_unavailable_observation_block",
             "escalation_level" => "payload_lead",
             "escalation_queue" => "payload_ops",
             "escalation_role" => "payload_scheduler",
             "sla_s" => 900,
             "source_resource_summary" => %{"spacecraft_id" => "sat_1"},
             "source_resource_suppression" => %{
               "id" => "obs_payload_blocked",
               "suppressed_reason" => "payload_unavailable"
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["source"] ==
                   "candidate_refresh.source_resource_filter_report.suppressed_candidates")
             )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh result artifact resource filter reports become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:wrapped_resource_filter_review:001",
      "source_result_artifact" => [
        %{
          "schema_contract" => "result_artifact.v1",
          "resource_filter_report" => %{
            "schema_contract" => "resource_filter_report.v1",
            "invalid_resource_summary_inputs" => [
              %{
                "resource_summary_id" => "resource_summary:wrapped_stale_sat",
                "spacecraft_id" => "sat_1",
                "invalid_resource_summary_input_reason" => "missing_resource_summary_epoch",
                "source_resource_summary" => %{
                  "resource_summary_id" => "resource_summary:wrapped_stale_sat"
                }
              }
            ],
            "suppressed_candidates" => [
              %{
                "id" => "obs_wrapped_payload_blocked",
                "type" => "observe",
                "spacecraft_id" => "sat_1",
                "target_id" => "target_a",
                "suppressed_reason" => "payload_unavailable",
                "payload_available" => false,
                "resource_blocking_dimension" => "payload",
                "resource_trust_boundary_status" => "declared",
                "approval_status" => "blocked_by_policy",
                "source_resource_summary" => %{"spacecraft_id" => "sat_1"}
              }
            ]
          }
        }
      ]
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:wrapped_resource_filter_review:001",
             "review_count" => 2,
             "resource_suppression_count" => 2
           } = package

    assert %{
             "review_type" => "resource_suppression",
             "source" =>
               "candidate_refresh.source_result_artifact[0].resource_filter_report.invalid_resource_summary_inputs",
             "subject_id" => "resource_summary:wrapped_stale_sat",
             "source_resource_summary" => %{
               "resource_summary_id" => "resource_summary:wrapped_stale_sat"
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["required_operator_action"] == "review_invalid_resource_filter_summary")
             )

    assert %{
             "review_type" => "resource_suppression",
             "source" =>
               "candidate_refresh.source_result_artifact[0].resource_filter_report.suppressed_candidates",
             "subject_id" => "obs_wrapped_payload_blocked",
             "activity_id" => "obs_wrapped_payload_blocked",
             "activity_type" => "observe",
             "required_operator_action" => "review_suppressed_observation",
             "approval_status" => "blocked_by_policy",
             "spacecraft_id" => "sat_1",
             "target_id" => "target_a",
             "payload_available" => false,
             "resource_blocking_dimension" => "payload",
             "resource_trust_boundary_status" => "declared",
             "source_resource_summary" => %{"spacecraft_id" => "sat_1"},
             "source_resource_suppression" => %{
               "id" => "obs_wrapped_payload_blocked",
               "suppressed_reason" => "payload_unavailable"
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["source"] ==
                   "candidate_refresh.source_result_artifact[0].resource_filter_report.suppressed_candidates")
             )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end
end
