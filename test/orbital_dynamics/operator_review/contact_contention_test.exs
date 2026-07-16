defmodule OrbitalDynamics.OperatorReview.ContactContentionTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{OperatorReview, Schema}

  test "contact contention report source ids fall back through defaults" do
    assert %{"source_artifact_id" => "contact-contention:report"} =
             OperatorReview.from_contact_contention_report(%{
               id: :"contact-contention:report"
             })

    assert %{"source_artifact_id" => "contact_contention_report"} =
             OperatorReview.from_contact_contention_report(%{})
  end

  test "builds review package from contact contention report groups" do
    report = %{
      "schema_contract" => "contact_contention_report.v1",
      "model" => "single_station_interval_overlap",
      "input_contact_count" => 2,
      "conflicted_contact_count" => 2,
      "conflict_group_count" => 1,
      "conflict_groups" => [
        %{
          "id" => "station:equator_prime:contention:1",
          "ground_station_id" => "equator_prime",
          "contact_count" => 2,
          "starts_at_s" => 100.0,
          "ends_at_s" => 220.0,
          "direction" => "downlink",
          "required_operator_action" => "review_contact_contention",
          "approval_status" => "operator_review_required",
          "operator_action_reason" => "same_station_overlapping_contact_windows",
          "approval_requirements" => [
            %{
              "activity_id" => "station:equator_prime:contention:1",
              "activity_type" => "contact_contention",
              "action" => "review_contact_contention",
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
          },
          "contact_ids" => ["dl_1", "dl_2"],
          "source_window_ids" => [
            "window:leo_1:ground_station_access:equator_prime:1",
            "window:leo_2:ground_station_access:equator_prime:1"
          ],
          "scenario_ids" => ["leo_1", "leo_2"]
        }
      ],
      "assumptions" => %{"resolution" => "report_only_no_candidate_suppression"}
    }

    package = OperatorReview.from_contact_contention_report(report)

    assert OrbitalDynamics.operator_review_package(report) == package

    assert %{
             "source_artifact_type" => "contact_contention_report.v1",
             "source_artifact_id" => "contact_contention_report",
             "review_count" => 1,
             "contention_review_count" => 1
           } = package

    assert %{
             "review_type" => "contact_contention_review",
             "subject_id" => "station:equator_prime:contention:1",
             "ground_station_id" => "equator_prime",
             "direction" => "downlink",
             "contact_count" => 2,
             "contact_ids" => ["dl_1", "dl_2"],
             "source_window_ids" => [
               "window:leo_1:ground_station_access:equator_prime:1",
               "window:leo_2:ground_station_access:equator_prime:1"
             ],
             "scenario_ids" => ["leo_1", "leo_2"],
             "required_operator_action" => "review_contact_contention",
             "approval_status" => "operator_review_required",
             "operator_action_reason" => "same_station_overlapping_contact_windows",
             "reason" => "review 2 overlapping contacts at equator_prime",
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
             "source_contention_group" => %{"contact_ids" => ["dl_1", "dl_2"]}
           } = List.first(package["rows"])

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    invalid_package =
      update_in(package, ["rows"], fn [row] ->
        [Map.put(row, "ground_station_id", "stale_station")]
      end)

    assert {:error, report} = Schema.validate_artifact(invalid_package)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].ground_station_id" and
                 &1["message"] == "must match source_contention_group.ground_station_id")
           )
  end

  test "validates contact contention invalid input source handoff rows" do
    report = %{
      "schema_contract" => "contact_contention_report.v1",
      "model" => "single_station_interval_overlap",
      "input_contact_count" => 1,
      "conflicted_contact_count" => 0,
      "conflict_group_count" => 0,
      "conflict_groups" => [],
      "invalid_contact_input_count" => 1,
      "invalid_contact_input_ids" => ["malformed_contact"],
      "invalid_contact_inputs" => [
        %{
          "id" => "invalid_contact:malformed_contact",
          "contact_id" => "malformed_contact",
          "ground_station_id" => "equator_prime",
          "starts_at_s" => 100.0,
          "ends_at_s" => 180.0,
          "direction" => "downlink",
          "required_operator_action" => "review_invalid_contact_contention_input",
          "approval_status" => "operator_review_required",
          "operator_action_reason" => "invalid_contact_shape",
          "invalid_contact_input" => true,
          "invalid_contact_input_reason" => "invalid_contact_shape"
        }
      ]
    }

    package = OperatorReview.from_contact_contention_report(report)

    assert %{
             "review_type" => "contact_contention_review",
             "subject_id" => "invalid_contact:malformed_contact",
             "contact_id" => "malformed_contact",
             "invalid_contact_input" => true,
             "invalid_contact_input_reason" => "invalid_contact_shape",
             "source_invalid_contact_input" => %{
               "ground_station_id" => "equator_prime",
               "invalid_contact_input_reason" => "invalid_contact_shape"
             }
           } = List.first(package["rows"])

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    invalid_package =
      update_in(package, ["rows"], fn [row] ->
        [Map.put(row, "invalid_contact_input_reason", "stale_reason")]
      end)

    assert {:error, report} = Schema.validate_artifact(invalid_package)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].invalid_contact_input_reason" and
                 &1["message"] ==
                   "must match source_invalid_contact_input.invalid_contact_input_reason")
           )
  end
end
