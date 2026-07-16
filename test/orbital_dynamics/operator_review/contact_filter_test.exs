defmodule OrbitalDynamics.OperatorReview.ContactFilterTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CadenceImport, OperatorReview, Schema}

  test "builds review package from standalone contact filter report suppressions" do
    report = %{
      "schema_contract" => "contact_filter_report.v1",
      "id" => "contact_filter:ground_network",
      "model" => "thin_ground_network_availability_filter",
      "input_candidate_count" => 2,
      "kept_candidate_count" => 1,
      "suppressed_candidate_count" => 1,
      "suppressed_candidates" => [
        %{
          "id" => "leo_1_downlink_equator_prime_1",
          "type" => "downlink",
          "scenario_id" => "leo_1",
          "starts_at_s" => 100.0,
          "ends_at_s" => 160.0,
          "ground_station_id" => "equator_prime",
          "direction" => "downlink",
          "station_availability" => "unavailable",
          "station_contention_status" => "reserved_overlap",
          "station_reservation_id" => "reservation_1",
          "station_reserved_by" => "network_partner",
          "station_reservation_status" => "confirmed",
          "station_reservation_match_status" => "overlap",
          "approval_status" => "blocked_by_policy",
          "approval_requirements" => [
            %{
              "activity_id" => "leo_1_downlink_equator_prime_1",
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
              %{"rule_id" => "unmatched_contact_rule", "escalation_queue" => "ignore_queue"},
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
          "source_window_id" => "window:leo_1:ground_station_access:equator_prime:1"
        }
      ],
      "provenance" => %{"source" => "test"}
    }

    package = OperatorReview.from_contact_filter_report(report)

    assert OrbitalDynamics.operator_review_package(report) == package

    assert %{
             "source_artifact_type" => "contact_filter_report.v1",
             "source_artifact_id" => "contact_filter:ground_network",
             "review_count" => 1,
             "contact_suppression_count" => 1
           } = package

    assert %{
             "review_type" => "contact_suppression",
             "source" => "contact_filter_report.suppressed_candidates",
             "activity_id" => "leo_1_downlink_equator_prime_1",
             "required_operator_action" => "review_suppressed_contact",
             "approval_status" => "blocked_by_policy",
             "direction" => "downlink",
             "requirement_type" => "contact_schedule_change",
             "required_authority" => "contact_schedule_authority",
             "policy_bundle_id" => "ground_network_allocation_v1",
             "rule_id" => "unavailable_station_contact_block",
             "escalation_level" => "ops_lead",
             "escalation_queue" => "ground_network",
             "escalation_role" => "network_scheduler",
             "sla_s" => 600,
             "station_contention_status" => "reserved_overlap",
             "station_reservation_id" => "reservation_1",
             "station_reserved_by" => "network_partner",
             "station_reservation_status" => "confirmed",
             "station_reservation_match_status" => "overlap",
             "approval_rule_matches" => [
               %{"rule_id" => "unavailable_station_contact_block"}
             ],
             "source_policy_decision" => %{
               "policy_bundle_id" => "ground_network_allocation_v1"
             },
             "source_policy_escalation" => %{
               "rule_id" => "unavailable_station_contact_block",
               "escalation_queue" => "ground_network"
             },
             "source_contact_suppression" => %{
               "suppressed_reason" => "ground_station_unavailable"
             }
           } = List.first(package["rows"])

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    manifest = CadenceImport.from_operator_review_package(package)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)

    assert %{
             "source_review_type" => "contact_suppression",
             "station_reservation_id" => "reservation_1",
             "source_review_row" => %{
               "review_type" => "contact_suppression",
               "station_reservation_id" => "reservation_1"
             }
           } = List.first(manifest["rows"])

    invalid_source_review_manifest =
      update_in(manifest, ["rows", Access.at(0), "source_review_row"], fn row ->
        Map.put(row, "station_reservation_id", "stale_reservation")
      end)

    assert {:error, source_review_report} =
             Schema.validate_artifact(invalid_source_review_manifest)

    assert Enum.any?(
             source_review_report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.station_reservation_id" and
                 &1["message"] == "must match station_reservation_id on Cadence import row")
           )

    invalid_package =
      update_in(package, ["rows"], fn [row] ->
        [Map.put(row, "station_reservation_id", "stale_reservation")]
      end)

    assert {:error, report} = Schema.validate_artifact(invalid_package)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].station_reservation_id" and
                 &1["message"] ==
                   "must match source_contact_suppression.station_reservation_id")
           )
  end

  test "routes planned-contact downlink suppressions through contact review actions" do
    report = %{
      "schema_contract" => "contact_filter_report.v1",
      "id" => "contact_filter:planned_contacts",
      "model" => "thin_ground_network_availability_filter",
      "input_candidate_count" => 1,
      "kept_candidate_count" => 0,
      "suppressed_candidate_count" => 1,
      "suppressed_candidates" => [
        %{
          "id" => "planned_downlink_1",
          "type" => "planned_contact",
          "direction" => "downlink",
          "scenario_id" => "leo_1",
          "ground_station_id" => "equator_prime",
          "suppressed_reason" => "ground_station_unavailable"
        }
      ]
    }

    package = OperatorReview.from_contact_filter_report(report)

    assert [
             %{
               "review_type" => "contact_suppression",
               "activity_id" => "planned_downlink_1",
               "activity_type" => "planned_contact",
               "direction" => "downlink",
               "action" => "review_suppressed_contact",
               "required_operator_action" => "review_suppressed_contact"
             }
           ] = package["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "contact filter report source ids fall back through defaults" do
    assert %{"source_artifact_id" => "contact-filter:report"} =
             OperatorReview.from_contact_filter_report(%{
               id: :"contact-filter:report",
               suppressed_candidates: []
             })

    assert %{"source_artifact_id" => "contact-filter:source"} =
             OperatorReview.from_contact_filter_report(%{
               source: :"contact-filter:source",
               suppressed_candidates: []
             })

    assert %{"source_artifact_id" => "contact_filter_report"} =
             OperatorReview.from_contact_filter_report(%{suppressed_candidates: []})
  end
end
