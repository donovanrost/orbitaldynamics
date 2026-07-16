defmodule OrbitalDynamics.OperatorReview.CandidateRefreshOperationalTimelineTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{OperatorReview, Schema}

  test "candidate refresh source operational timeline reports become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:ops_timeline_review:001",
      "source_operational_timeline_report" => %{
        "schema_contract" => "operational_timeline_report.v1",
        "source" => "mission_state.source_operational_timeline_report",
        "rows" => [
          %{
            "activity_id" => "cmd_live_timeline",
            "timeline_id" => "timeline:leo_1:command:cmd_live_timeline",
            "scenario_id" => "leo_1",
            "activity_type" => "command",
            "operational_kind" => "command",
            "starts_at_s" => 100.0,
            "ends_at_s" => 130.0,
            "status" => "planned",
            "approval_status" => "review_required",
            "required_operator_action" => "review_command_feedback",
            "operator_action_reason" => "live command result requires operator review",
            "cadence_import_status" => "present",
            "command_success_factor" => 0.3,
            "command_result" => ["accepted", "failed"],
            "trust_boundary" => "cadence_live_timeline_export"
          }
        ]
      }
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:ops_timeline_review:001",
             "review_count" => 1,
             "operational_timeline_count" => 1,
             "cadence_import_status_counts" => %{"present" => 1}
           } = package

    assert %{
             "review_type" => "operational_timeline_review",
             "source" => "candidate_refresh.source_operational_timeline_report.rows",
             "subject_id" => "timeline:leo_1:command:cmd_live_timeline",
             "activity_id" => "cmd_live_timeline",
             "timeline_id" => "timeline:leo_1:command:cmd_live_timeline",
             "operational_kind" => "command",
             "required_operator_action" => "review_command_feedback",
             "approval_status" => "review_required",
             "source_approval_status" => "review_required",
             "cadence_import_status" => "present",
             "command_success_factor" => 0.3,
             "command_result" => "accepted,failed",
             "trust_boundary" => "cadence_live_timeline_export",
             "source_operational_timeline" => %{
               "activity_id" => "cmd_live_timeline",
               "timeline_id" => "timeline:leo_1:command:cmd_live_timeline"
             }
           } = List.first(package["rows"])

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh result artifact operational timeline reports become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:wrapped_ops_timeline_review:001",
      "source_result_artifact" => %{
        "schema_contract" => "result_artifact.v1",
        "operational_timeline_report" => %{
          "schema_contract" => "operational_timeline_report.v1",
          "source" => "wrapped.operational_timeline_report",
          "rows" => [
            %{
              "activity_id" => "cmd_wrapped_timeline",
              "timeline_id" => "timeline:leo_1:command:cmd_wrapped_timeline",
              "scenario_id" => "leo_1",
              "activity_type" => "command",
              "operational_kind" => "command",
              "starts_at_s" => 100.0,
              "ends_at_s" => 130.0,
              "status" => "planned",
              "approval_status" => "review_required",
              "required_operator_action" => "review_command_feedback",
              "operator_action_reason" => "live command result requires operator review",
              "cadence_import_status" => "present",
              "command_success_factor" => 0.3,
              "command_result" => ["accepted", "failed"],
              "trust_boundary" => "cadence_live_timeline_export"
            }
          ]
        }
      }
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:wrapped_ops_timeline_review:001",
             "review_count" => 1,
             "operational_timeline_count" => 1,
             "cadence_import_status_counts" => %{"present" => 1}
           } = package

    assert %{
             "review_type" => "operational_timeline_review",
             "source" =>
               "candidate_refresh.source_result_artifact.operational_timeline_report.rows",
             "subject_id" => "timeline:leo_1:command:cmd_wrapped_timeline",
             "activity_id" => "cmd_wrapped_timeline",
             "timeline_id" => "timeline:leo_1:command:cmd_wrapped_timeline",
             "operational_kind" => "command",
             "required_operator_action" => "review_command_feedback",
             "approval_status" => "review_required",
             "source_approval_status" => "review_required",
             "cadence_import_status" => "present",
             "command_success_factor" => 0.3,
             "command_result" => "accepted,failed",
             "trust_boundary" => "cadence_live_timeline_export",
             "source_operational_timeline" => %{
               "activity_id" => "cmd_wrapped_timeline",
               "timeline_id" => "timeline:leo_1:command:cmd_wrapped_timeline"
             }
           } = List.first(package["rows"])

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end
end
