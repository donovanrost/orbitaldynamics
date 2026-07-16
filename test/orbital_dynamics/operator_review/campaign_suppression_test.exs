defmodule OrbitalDynamics.OperatorReview.CampaignSuppressionTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{OperatorReview, Schema}

  test "builds campaign review package from contact and resource filter suppressions" do
    artifact = %{
      "schema_version" => 1,
      "plan_id" => "campaign_plan:resource_filter",
      "contact_contention_resolution_report" => %{"recommendations" => []},
      "contact_filter_report" => %{
        "schema_contract" => "contact_filter_report.v1",
        "model" => "ground_station_availability_filter",
        "input_contact_count" => 2,
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
            "station_availability" => "unavailable",
            "suppressed_reason" => "ground_station_unavailable",
            "source_window_id" => "window:leo_1:ground_station_access:equator_prime:1"
          }
        ]
      },
      "resource_filter_report" => %{
        "schema_contract" => "resource_filter_report.v1",
        "model" => "resource_summary_availability_and_margin_filter",
        "input_candidate_count" => 2,
        "kept_candidate_count" => 1,
        "suppressed_candidate_count" => 1,
        "suppressed_candidates" => [
          %{
            "id" => "leo_1_observe_target_a_1",
            "type" => "observe",
            "scenario_id" => "leo_1",
            "starts_at_s" => 60.0,
            "ends_at_s" => 180.0,
            "suppressed_reason" => "payload_unavailable",
            "resource_trust_boundary_status" => "missing",
            "source_window_id" => "window:leo_1:target_visibility:target_a:1"
          }
        ]
      },
      "warnings" => [],
      "provenance" => %{"source" => "campaign_test"}
    }

    package = OperatorReview.from_campaign_artifact(artifact)

    assert %{
             "source_artifact_type" => "campaign_plan.v1",
             "source_artifact_id" => "campaign_plan:resource_filter",
             "review_count" => 2,
             "contact_suppression_count" => 1,
             "resource_suppression_count" => 1
           } = package

    assert %{
             "review_type" => "contact_suppression",
             "activity_id" => "leo_1_downlink_equator_prime_1",
             "activity_type" => "downlink",
             "required_operator_action" => "review_suppressed_contact",
             "reason" => "contact filter suppressed candidate: ground_station_unavailable",
             "ground_station_id" => "equator_prime",
             "station_availability" => "unavailable",
             "source" => "campaign_plan.contact_filter_report.suppressed_candidates",
             "source_contact_suppression" => %{
               "suppressed_reason" => "ground_station_unavailable"
             }
           } = Enum.find(package["rows"], &(&1["review_type"] == "contact_suppression"))

    assert %{
             "review_type" => "resource_suppression",
             "activity_id" => "leo_1_observe_target_a_1",
             "activity_type" => "observe",
             "required_operator_action" => "review_suppressed_observation",
             "reason" => "resource filter suppressed candidate: payload_unavailable",
             "resource_trust_boundary_status" => "missing",
             "source_window_id" => "window:leo_1:target_visibility:target_a:1",
             "source_resource_suppression" => %{
               "suppressed_reason" => "payload_unavailable",
               "resource_trust_boundary_status" => "missing"
             }
           } = Enum.find(package["rows"], &(&1["review_type"] == "resource_suppression"))

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end
end
