defmodule OrbitalDynamics.OperatorReview.CandidateRefreshContactFilterTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{OperatorReview, Schema}

  test "candidate refresh source contact filter reports become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:contact_filter_review:001",
      "source_contact_filter_report" => %{
        "schema_contract" => "contact_filter_report.v1",
        "id" => "source_contact_filter:mission_state",
        "model" => "thin_ground_network_availability_filter",
        "suppressed_candidates" => [
          %{
            "id" => "dl_source_suppressed",
            "base_candidate_id" => "dl_source",
            "type" => "downlink",
            "scenario_id" => "leo_1",
            "starts_at_s" => 100.0,
            "ends_at_s" => 160.0,
            "ground_station_id" => "equator_prime",
            "direction" => "downlink",
            "station_availability" => "unavailable",
            "station_contention_status" => "reserved_overlap",
            "station_reservation_id" => "reservation:equator_prime:dl_source_suppressed",
            "station_reserved_by" => "network_partner",
            "station_reservation_status" => "confirmed",
            "station_reservation_match_status" => "overlap",
            "approval_status" => "blocked_by_policy",
            "approval_requirements" => [
              %{
                "activity_id" => "dl_source_suppressed",
                "activity_type" => "downlink",
                "action" => "review_suppressed_contact",
                "requirement_type" => "contact_schedule_change",
                "reason" => "ground_station_unavailable"
              }
            ],
            "approval_rule_matches" => [
              %{"rule_id" => "unavailable_station_contact_block"}
            ],
            "policy_decision" => %{
              "schema_contract" => "policy_decision.v1",
              "policy_bundle_id" => "ground_network_allocation_v1",
              "escalations" => [
                %{
                  "rule_id" => "unavailable_station_contact_block",
                  "required_authority" => "contact_schedule_authority",
                  "escalation_level" => "ops_lead",
                  "escalation_queue" => "ground_network",
                  "escalation_role" => "network_scheduler",
                  "sla_s" => 600
                }
              ]
            },
            "suppressed_reason" => "ground_station_unavailable",
            "duplicate_suppressed_candidate_id_collision" => true,
            "duplicate_suppressed_candidate_index" => 1,
            "duplicate_suppressed_candidate_count" => 1,
            "source_window_id" => "window:leo_1:ground_station_access:equator_prime:1",
            "source_contact_candidate" => %{"id" => "dl_source_suppressed"}
          }
        ]
      }
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:contact_filter_review:001",
             "review_count" => 1,
             "contact_suppression_count" => 1
           } = package

    assert [
             %{
               "review_type" => "contact_suppression",
               "source" => "candidate_refresh.source_contact_filter_report.suppressed_candidates",
               "subject_id" => "dl_source_suppressed",
               "activity_id" => "dl_source_suppressed",
               "base_candidate_id" => "dl_source",
               "activity_type" => "downlink",
               "required_operator_action" => "review_suppressed_contact",
               "approval_status" => "blocked_by_policy",
               "reason" => "contact filter suppressed candidate: ground_station_unavailable",
               "ground_station_id" => "equator_prime",
               "direction" => "downlink",
               "station_availability" => "unavailable",
               "station_contention_status" => "reserved_overlap",
               "station_reservation_id" => "reservation:equator_prime:dl_source_suppressed",
               "station_reserved_by" => "network_partner",
               "station_reservation_status" => "confirmed",
               "station_reservation_match_status" => "overlap",
               "requirement_type" => "contact_schedule_change",
               "required_authority" => "contact_schedule_authority",
               "policy_bundle_id" => "ground_network_allocation_v1",
               "rule_id" => "unavailable_station_contact_block",
               "escalation_level" => "ops_lead",
               "escalation_queue" => "ground_network",
               "escalation_role" => "network_scheduler",
               "sla_s" => 600,
               "duplicate_suppressed_candidate_id_collision" => true,
               "duplicate_suppressed_candidate_index" => 1,
               "duplicate_suppressed_candidate_count" => 1,
               "source_window_id" => "window:leo_1:ground_station_access:equator_prime:1",
               "source_contact_candidate" => %{"id" => "dl_source_suppressed"},
               "source_contact_suppression" => %{
                 "id" => "dl_source_suppressed",
                 "suppressed_reason" => "ground_station_unavailable"
               },
               "source_policy_decision" => %{
                 "policy_bundle_id" => "ground_network_allocation_v1"
               }
             }
           ] = package["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh result artifact contact filter reports become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:wrapped_contact_filter_review:001",
      "result_artifact" => %{
        "schema_contract" => "result_artifact.v1",
        "source_contact_filter_report" => %{
          "schema_contract" => "contact_filter_report.v1",
          "suppressed_candidates" => [
            %{
              "id" => "dl_wrapped_suppressed",
              "base_candidate_id" => "dl_wrapped",
              "type" => "downlink",
              "ground_station_id" => "equator_prime",
              "direction" => "downlink",
              "station_availability" => "unavailable",
              "station_contention_status" => "reserved_overlap",
              "station_reservation_id" => "reservation:equator_prime:dl_wrapped_suppressed",
              "station_reserved_by" => "network_partner",
              "station_reservation_status" => "confirmed",
              "station_reservation_match_status" => "overlap",
              "approval_status" => "blocked_by_policy",
              "approval_requirements" => [
                %{
                  "activity_id" => "dl_wrapped_suppressed",
                  "activity_type" => "downlink",
                  "action" => "review_suppressed_contact",
                  "requirement_type" => "contact_schedule_change"
                }
              ],
              "policy_decision" => %{
                "schema_contract" => "policy_decision.v1",
                "policy_bundle_id" => "ground_network_allocation_v1"
              },
              "suppressed_reason" => "ground_station_unavailable",
              "source_window_id" => "window:leo_1:ground_station_access:equator_prime:1",
              "source_contact_candidate" => %{"id" => "dl_wrapped_suppressed"}
            }
          ]
        }
      }
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:wrapped_contact_filter_review:001",
             "review_count" => 1,
             "contact_suppression_count" => 1
           } = package

    assert [
             %{
               "review_type" => "contact_suppression",
               "source" =>
                 "candidate_refresh.result_artifact.source_contact_filter_report.suppressed_candidates",
               "subject_id" => "dl_wrapped_suppressed",
               "activity_id" => "dl_wrapped_suppressed",
               "base_candidate_id" => "dl_wrapped",
               "activity_type" => "downlink",
               "required_operator_action" => "review_suppressed_contact",
               "approval_status" => "blocked_by_policy",
               "ground_station_id" => "equator_prime",
               "direction" => "downlink",
               "station_availability" => "unavailable",
               "station_contention_status" => "reserved_overlap",
               "station_reservation_id" => "reservation:equator_prime:dl_wrapped_suppressed",
               "station_reserved_by" => "network_partner",
               "station_reservation_status" => "confirmed",
               "station_reservation_match_status" => "overlap",
               "requirement_type" => "contact_schedule_change",
               "policy_bundle_id" => "ground_network_allocation_v1",
               "source_window_id" => "window:leo_1:ground_station_access:equator_prime:1",
               "source_contact_candidate" => %{"id" => "dl_wrapped_suppressed"},
               "source_contact_suppression" => %{
                 "id" => "dl_wrapped_suppressed",
                 "suppressed_reason" => "ground_station_unavailable"
               },
               "source_policy_decision" => %{
                 "policy_bundle_id" => "ground_network_allocation_v1"
               }
             }
           ] = package["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end
end
