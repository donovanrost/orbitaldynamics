defmodule OrbitalDynamics.OperatorReview.CommandWindowTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{OperatorReview, Schema}

  test "builds review package from operator-relevant command window rows" do
    report = %{
      "schema_contract" => "command_window_report.v1",
      "model" => "artifact_only_command_window_report",
      "source" => "mission_plan.activities",
      "window_count" => 2,
      "command_count" => 1,
      "tracking_count" => 1,
      "uplink_count" => 0,
      "health_check_count" => 0,
      "review_required_count" => 1,
      "source_window_lineage_count" => 1,
      "rows" => [
        %{
          "id" => "command_window:cmd_1",
          "rank" => 1,
          "activity_id" => "cmd_1",
          "timeline_id" => "timeline:cmd_1",
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
          "command_result" => [:accepted, :rejected],
          "command_success_factor" => 0.25,
          "command_success_factor_source" => "operational_feedback.command_success_rate.activity",
          "required_operator_action" => "review_command_contact",
          "operator_action_reason" => "command_boundary_requires_review",
          "approval_requirements" => [
            %{
              "activity_id" => "cmd_1",
              "activity_type" => "command",
              "action" => "review_command_contact",
              "requirement_type" => "command_review",
              "policy_classification" => "operator_review_required"
            }
          ],
          "approval_rule_matches" => [
            %{
              "rule_id" => "command_health_review",
              "classification" => "operator_review_required",
              "requirement_type" => "command_review"
            }
          ],
          "policy_decision" => %{
            "schema_contract" => "policy_decision.v1",
            "classification" => "operator_review_required",
            "policy_bundle_id" => "contact_command_review_v1",
            "rule_matches" => [
              %{
                "rule_id" => "command_health_review",
                "classification" => "operator_review_required"
              }
            ],
            "escalations" => [
              %{"rule_id" => "unmatched_command_rule", "escalation_queue" => "ignore_queue"},
              %{
                "rule_id" => "command_health_review",
                "required_authority" => "command_authority",
                "escalation_level" => "flight_director",
                "escalation_queue" => "command_review",
                "escalation_role" => "command_authorizer",
                "sla_s" => 300
              }
            ],
            "approval_requirement_count" => 1,
            "risk_count" => 0
          },
          "execution_boundary" => "planned_not_commanded",
          "cadence_import_status" => "missing",
          "source_window_id" => "cmd_window_1",
          "has_source_window" => true,
          "has_cadence_import" => false,
          "timeline_identity" => %{
            "timeline_id" => "timeline:cmd_1",
            "activity_id" => "cmd_1"
          },
          "activity_context" => %{
            "starts_at_s" => 30.0,
            "ends_at_s" => 40.0,
            "source_window_id" => "cmd_window_1",
            "command_success" => false,
            "contact_result" => ["accepted", "dropped"],
            "command_result" => [:accepted, :rejected],
            "command_success_factor" => 0.25,
            "timeline_identity" => %{
              "timeline_id" => "timeline:cmd_1",
              "activity_id" => "cmd_1",
              "source_window_id" => "cmd_window_1"
            }
          }
        },
        %{
          "id" => "command_window:track_1",
          "rank" => 2,
          "activity_id" => "track_1",
          "timeline_id" => "timeline:track_1",
          "activity_type" => "tracking",
          "window_type" => "tracking_window",
          "starts_at_s" => 50.0,
          "ends_at_s" => 60.0,
          "status" => "planned",
          "approval_status" => "approved",
          "locked" => false,
          "required_operator_action" => "monitor_activity",
          "execution_boundary" => "planned_not_commanded",
          "cadence_import_status" => "present",
          "has_source_window" => false,
          "has_cadence_import" => true,
          "timeline_identity" => %{"timeline_id" => "timeline:track_1"}
        }
      ],
      "assumptions" => %{"boundary" => "artifact_only_no_schedule_mutation_or_command_execution"}
    }

    package = OperatorReview.from_command_window_report(report)

    assert OrbitalDynamics.operator_review_package(report) == package

    assert %{
             "source_artifact_type" => "command_window_report.v1",
             "source_artifact_id" => "mission_plan.activities",
             "review_count" => 1,
             "command_window_count" => 1
           } = package

    assert %{
             "review_type" => "command_window_review",
             "activity_id" => "cmd_1",
             "timeline_id" => "timeline:cmd_1",
             "window_type" => "command_window",
             "required_operator_action" => "review_command_contact",
             "reason" => "command_boundary_requires_review",
             "cadence_import_status" => "missing",
             "command_success" => false,
             "contact_result" => "accepted,dropped",
             "command_result" => "accepted,rejected",
             "command_success_factor" => 0.25,
             "approval_rule_matches" => [
               %{"rule_id" => "command_health_review"}
             ],
             "requirement_type" => "command_review",
             "required_authority" => "command_authority",
             "policy_bundle_id" => "contact_command_review_v1",
             "rule_id" => "command_health_review",
             "escalation_level" => "flight_director",
             "escalation_queue" => "command_review",
             "escalation_role" => "command_authorizer",
             "sla_s" => 300,
             "source_policy_decision" => %{
               "policy_bundle_id" => "contact_command_review_v1"
             },
             "source_policy_escalation" => %{
               "rule_id" => "command_health_review",
               "escalation_queue" => "command_review"
             },
             "source_activity_context" => %{
               "source_window_id" => "cmd_window_1",
               "contact_result" => "accepted,dropped",
               "command_result" => "accepted,rejected",
               "timeline_identity" => %{
                 "timeline_id" => "timeline:cmd_1",
                 "activity_id" => "cmd_1",
                 "source_window_id" => "cmd_window_1"
               }
             },
             "source_command_window" => %{"activity_id" => "cmd_1"}
           } = List.first(package["rows"])

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    invalid_package =
      update_in(package, ["rows"], fn [row] ->
        [
          row
          |> Map.put("source_window_id", "stale_source_window")
          |> Map.put("execution_boundary", "stale_execution_boundary")
        ]
      end)

    assert {:error, report} = Schema.validate_artifact(invalid_package)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].source_window_id" and
                 &1["message"] == "must match source_command_window.source_window_id")
           )

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].execution_boundary" and
                 &1["message"] == "must match source_command_window.execution_boundary")
           )
  end

  test "command window report source ids fall back through defaults" do
    assert %{"source_artifact_id" => "command-window:report"} =
             OperatorReview.from_command_window_report(%{
               id: :"command-window:report",
               rows: []
             })

    assert %{"source_artifact_id" => "command-window:source"} =
             OperatorReview.from_command_window_report(%{
               source: :"command-window:source",
               rows: []
             })

    assert %{"source_artifact_id" => "command_window_report"} =
             OperatorReview.from_command_window_report(%{rows: []})
  end
end
