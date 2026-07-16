defmodule OrbitalDynamics.OperatorReview.ContactContentionResolutionTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{OperatorReview, Schema}

  test "contact contention resolution report source ids fall back through defaults" do
    assert %{"source_artifact_id" => "contact-contention:resolution"} =
             OperatorReview.from_contact_contention_resolution_report(%{
               id: :"contact-contention:resolution"
             })

    assert %{"source_artifact_id" => "contact_contention_resolution_report"} =
             OperatorReview.from_contact_contention_resolution_report(%{})
  end

  test "builds review package from standalone contact contention resolution report" do
    report = %{
      "schema_contract" => "contact_contention_resolution_report.v1",
      "model" => "deterministic_contact_contention_recommendation",
      "policy" => %{
        "selection_rule" => "highest_score_earliest_start",
        "tie_breakers" => ["starts_at_s", "id"],
        "action" => "recommend_preferred_contact_for_operator_review"
      },
      "conflict_group_count" => 1,
      "recommendation_count" => 1,
      "recommendations" => [
        %{
          "group_id" => "station:equator_prime:contention:1",
          "ground_station_id" => "equator_prime",
          "starts_at_s" => 100.0,
          "ends_at_s" => 220.0,
          "selected_contact_id" => "dl_1",
          "deferred_contact_ids" => ["dl_2"],
          "candidate_count" => 2,
          "selection_reason" => "highest_score_earliest_start",
          "action" => "recommend_preferred_contact_for_operator_review",
          "review_status" => "operator_review_required",
          "approval_requirements" => [
            %{
              "activity_id" => "station:equator_prime:contention:1",
              "activity_type" => "contact_contention_resolution",
              "action" => "recommend_preferred_contact_for_operator_review",
              "requirement_type" => "contact_schedule_change",
              "policy_classification" => "operator_review_required"
            }
          ],
          "approval_rule_matches" => [
            %{
              "rule_id" => "contact_schedule_review",
              "classification" => "operator_review_required",
              "requirement_type" => "contact_schedule_change"
            }
          ],
          "policy_decision" => %{
            "schema_contract" => "policy_decision.v1",
            "classification" => "operator_review_required",
            "policy_bundle_id" => "contact_command_review_v1",
            "rule_matches" => [
              %{
                "rule_id" => "contact_schedule_review",
                "classification" => "operator_review_required"
              }
            ],
            "escalations" => [
              %{
                "rule_id" => "unmatched_contention_rule",
                "escalation_queue" => "ignore_queue"
              },
              %{
                "rule_id" => "contact_schedule_review",
                "required_authority" => "contact_schedule_authority",
                "escalation_level" => "ops_lead",
                "escalation_queue" => "ground_network",
                "escalation_role" => "network_scheduler",
                "sla_s" => 600
              }
            ],
            "approval_requirement_count" => 1,
            "risk_count" => 0
          }
        }
      ],
      "assumptions" => %{"boundary" => "recommendation_only_no_station_reservation"}
    }

    package = OperatorReview.from_contact_contention_resolution_report(report)

    assert OrbitalDynamics.operator_review_package(report) == package

    assert %{
             "source_artifact_type" => "contact_contention_resolution_report.v1",
             "source_artifact_id" => "contact_contention_resolution_report",
             "review_count" => 1,
             "contention_recommendation_count" => 1
           } = package

    assert %{
             "review_type" => "contact_contention_recommendation",
             "source" => "contact_contention_resolution_report.recommendations",
             "subject_id" => "station:equator_prime:contention:1",
             "selected_contact_id" => "dl_1",
             "deferred_contact_ids" => ["dl_2"],
             "required_operator_action" => "recommend_preferred_contact_for_operator_review",
             "required_authority" => "contact_schedule_authority",
             "policy_bundle_id" => "contact_command_review_v1",
             "rule_id" => "contact_schedule_review",
             "escalation_level" => "ops_lead",
             "escalation_queue" => "ground_network",
             "escalation_role" => "network_scheduler",
             "sla_s" => 600,
             "approval_rule_matches" => [
               %{"rule_id" => "contact_schedule_review"}
             ],
             "source_policy_decision" => %{
               "policy_bundle_id" => "contact_command_review_v1"
             },
             "source_policy_escalation" => %{
               "rule_id" => "contact_schedule_review",
               "escalation_queue" => "ground_network"
             },
             "source_recommendation" => %{"selected_contact_id" => "dl_1"}
           } = List.first(package["rows"])

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    invalid_source_evidence =
      update_in(package, ["rows"], fn [row] ->
        [
          put_in(
            row,
            ["source_recommendation", "selected_contact_id"],
            "selected contact with spaces"
          )
        ]
      end)

    assert {:error, report} = Schema.validate_artifact(invalid_source_evidence)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].source_recommendation.selected_contact_id")
           )

    invalid_package =
      update_in(package, ["rows"], fn [row] ->
        [Map.put(row, "selected_contact_id", "stale_contact")]
      end)

    assert {:error, report} = Schema.validate_artifact(invalid_package)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].selected_contact_id" and
                 &1["message"] == "must match source_recommendation.selected_contact_id")
           )
  end
end
