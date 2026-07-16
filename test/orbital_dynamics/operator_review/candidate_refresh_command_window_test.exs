defmodule OrbitalDynamics.OperatorReview.CandidateRefreshCommandWindowTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{OperatorReview, Schema}

  test "candidate refresh source command window reports become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:source_command_window_review:001",
      "source_command_window_report" => [
        %{
          "schema_contract" => "command_window_report.v1",
          "source" => "mission_state.source_command_window_report",
          "rows" => [
            %{
              "id" => "command_window:cmd_live",
              "activity_id" => "cmd_live",
              "timeline_id" => "timeline:cmd_live",
              "scenario_id" => "leo_1",
              "activity_type" => "command",
              "window_type" => "command_window",
              "direction" => "command",
              "ground_station_id" => "dss_14",
              "starts_at_s" => 30.0,
              "ends_at_s" => 40.0,
              "status" => "planned",
              "approval_status" => "pending",
              "locked" => false,
              "command_success" => false,
              "contact_result" => ["accepted", "dropped"],
              "command_result" => ["accepted", "rejected"],
              "command_success_factor" => 0.25,
              "command_success_factor_source" =>
                "source_command_window_report.operational_feedback",
              "required_operator_action" => "review_command_contact",
              "operator_action_reason" => "command_boundary_requires_review",
              "approval_requirements" => [
                %{
                  "activity_id" => "cmd_live",
                  "activity_type" => "command",
                  "action" => "review_command_contact",
                  "requirement_type" => "command_review"
                }
              ],
              "policy_decision" => %{
                "schema_contract" => "policy_decision.v1",
                "classification" => "operator_review_required",
                "policy_bundle_id" => "contact_command_review_v1",
                "escalations" => [
                  %{
                    "rule_id" => "command_health_review",
                    "required_authority" => "command_authority",
                    "escalation_level" => "flight_director",
                    "escalation_queue" => "command_review",
                    "escalation_role" => "command_authorizer",
                    "sla_s" => 300
                  }
                ]
              },
              "execution_boundary" => "planned_not_commanded",
              "cadence_import_status" => "missing",
              "activity_context" => %{
                "command_result" => ["accepted", "rejected"],
                "command_success_factor" => 0.25
              }
            }
          ]
        }
      ]
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:source_command_window_review:001",
             "review_count" => 1,
             "command_window_count" => 1
           } = package

    assert [
             %{
               "review_type" => "command_window_review",
               "source" => "candidate_refresh.source_command_window_report[0].rows",
               "activity_id" => "cmd_live",
               "timeline_id" => "timeline:cmd_live",
               "window_type" => "command_window",
               "required_operator_action" => "review_command_contact",
               "reason" => "command_boundary_requires_review",
               "command_success" => false,
               "command_result" => "accepted,rejected",
               "command_success_factor" => 0.25,
               "requirement_type" => "command_review",
               "policy_bundle_id" => "contact_command_review_v1",
               "required_authority" => "command_authority",
               "escalation_queue" => "command_review",
               "source_command_window" => %{"activity_id" => "cmd_live"},
               "source_activity_context" => %{"command_result" => "accepted,rejected"}
             }
           ] = package["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh result artifact command window reports become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:wrapped_command_window_review:001",
      "source_result_artifact" => %{
        "schema_contract" => "result_artifact.v1",
        "command_window_report" => %{
          "schema_contract" => "command_window_report.v1",
          "source" => "wrapped.command_window_report",
          "rows" => [
            %{
              "id" => "command_window:cmd_wrapped",
              "activity_id" => "cmd_wrapped",
              "timeline_id" => "timeline:cmd_wrapped",
              "scenario_id" => "leo_1",
              "activity_type" => "command",
              "window_type" => "command_window",
              "direction" => "command",
              "ground_station_id" => "dss_14",
              "starts_at_s" => 30.0,
              "ends_at_s" => 40.0,
              "status" => "planned",
              "approval_status" => "pending",
              "locked" => false,
              "command_success" => false,
              "contact_result" => ["accepted", "dropped"],
              "command_result" => ["accepted", "rejected"],
              "command_success_factor" => 0.25,
              "command_success_factor_source" =>
                "source_command_window_report.operational_feedback",
              "required_operator_action" => "review_command_contact",
              "operator_action_reason" => "command_boundary_requires_review",
              "approval_requirements" => [
                %{
                  "activity_id" => "cmd_wrapped",
                  "activity_type" => "command",
                  "action" => "review_command_contact",
                  "requirement_type" => "command_review"
                }
              ],
              "policy_decision" => %{
                "schema_contract" => "policy_decision.v1",
                "classification" => "operator_review_required",
                "policy_bundle_id" => "contact_command_review_v1",
                "escalations" => [
                  %{
                    "rule_id" => "command_health_review",
                    "required_authority" => "command_authority",
                    "escalation_level" => "flight_director",
                    "escalation_queue" => "command_review",
                    "escalation_role" => "command_authorizer",
                    "sla_s" => 300
                  }
                ]
              },
              "execution_boundary" => "planned_not_commanded",
              "cadence_import_status" => "missing",
              "activity_context" => %{
                "command_result" => ["accepted", "rejected"],
                "command_success_factor" => 0.25
              }
            }
          ]
        }
      }
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:wrapped_command_window_review:001",
             "review_count" => 1,
             "command_window_count" => 1
           } = package

    assert [
             %{
               "review_type" => "command_window_review",
               "source" => "candidate_refresh.source_result_artifact.command_window_report.rows",
               "activity_id" => "cmd_wrapped",
               "timeline_id" => "timeline:cmd_wrapped",
               "window_type" => "command_window",
               "required_operator_action" => "review_command_contact",
               "reason" => "command_boundary_requires_review",
               "command_success" => false,
               "command_result" => "accepted,rejected",
               "command_success_factor" => 0.25,
               "requirement_type" => "command_review",
               "policy_bundle_id" => "contact_command_review_v1",
               "required_authority" => "command_authority",
               "escalation_queue" => "command_review",
               "source_command_window" => %{"activity_id" => "cmd_wrapped"},
               "source_activity_context" => %{"command_result" => "accepted,rejected"}
             }
           ] = package["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end
end
