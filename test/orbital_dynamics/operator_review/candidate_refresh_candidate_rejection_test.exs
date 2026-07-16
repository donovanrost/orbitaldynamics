defmodule OrbitalDynamics.OperatorReview.CandidateRefreshCandidateRejectionTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{OperatorReview, Schema}

  test "candidate refresh source candidate rejection reports become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:source_candidate_rejection_review:001",
      "source_candidate_rejection_report" => [
        %{
          "schema_contract" => "candidate_rejection_report.v1",
          "source" => "mission_state.source_candidate_rejection_report",
          "rows" => [
            %{
              "candidate_id" => "refresh_downlink_reserved",
              "activity_id" => "refresh_downlink_reserved",
              "timeline_id" => "timeline:leo_1:contact:refresh_downlink_reserved",
              "activity_type" => "contact",
              "operational_kind" => "downlink",
              "source_window_id" => "window:leo_1:equator_prime:1",
              "source_window_type" => "ground_station_access",
              "rejection_status" => "rejected",
              "reviewable" => true,
              "primary_rejection_reason" => "station_reserved",
              "rejection_reasons" => ["station_reserved"],
              "reason_count" => 1,
              "required_operator_action" => "review_candidate_rejection"
            }
          ]
        }
      ]
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:source_candidate_rejection_review:001",
             "review_count" => 1,
             "candidate_rejection_review_count" => 1
           } = package

    assert [
             %{
               "review_type" => "candidate_rejection_review",
               "source" => "candidate_refresh.source_candidate_rejection_report[0].rows",
               "subject_id" => "refresh_downlink_reserved",
               "candidate_id" => "refresh_downlink_reserved",
               "activity_id" => "refresh_downlink_reserved",
               "activity_type" => "contact",
               "operational_kind" => "downlink",
               "source_window_id" => "window:leo_1:equator_prime:1",
               "source_window_type" => "ground_station_access",
               "candidate_rejection_status" => "rejected",
               "candidate_rejection_reasons" => ["station_reserved"],
               "primary_rejection_reason" => "station_reserved",
               "candidate_rejection_reason_count" => 1,
               "reviewable" => true,
               "required_operator_action" => "review_candidate_rejection",
               "source_candidate_rejection" => %{
                 "candidate_id" => "refresh_downlink_reserved",
                 "primary_rejection_reason" => "station_reserved"
               }
             }
           ] = package["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh result artifact candidate rejection reports become operator review rows" do
    report = %{
      "schema_contract" => "candidate_rejection_report.v1",
      "source" => "mission_state.source_result_artifact.candidate_rejection_report",
      "rows" => [
        %{
          "candidate_id" => "wrapped_downlink_rejected",
          "activity_id" => "wrapped_downlink_rejected",
          "timeline_id" => "timeline:leo_1:contact:wrapped_downlink_rejected",
          "activity_type" => "contact",
          "operational_kind" => "downlink",
          "source_window_id" => "window:leo_1:equator_prime:wrapped",
          "source_window_type" => "ground_station_access",
          "rejection_status" => "rejected",
          "reviewable" => true,
          "primary_rejection_reason" => "station_reserved",
          "rejection_reasons" => ["station_reserved"],
          "reason_count" => 1,
          "required_operator_action" => "review_candidate_rejection"
        }
      ]
    }

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:wrapped_candidate_rejection_review:001",
      "source_result_artifact" => %{
        "schema_contract" => "result_artifact.v1",
        "candidate_rejection_report" => report
      }
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:wrapped_candidate_rejection_review:001",
             "review_count" => 1,
             "candidate_rejection_review_count" => 1
           } = package

    assert [
             %{
               "review_type" => "candidate_rejection_review",
               "source" =>
                 "candidate_refresh.source_result_artifact.candidate_rejection_report.rows",
               "subject_id" => "wrapped_downlink_rejected",
               "candidate_id" => "wrapped_downlink_rejected",
               "activity_id" => "wrapped_downlink_rejected",
               "primary_rejection_reason" => "station_reserved",
               "required_operator_action" => "review_candidate_rejection",
               "source_candidate_rejection" => %{
                 "candidate_id" => "wrapped_downlink_rejected"
               }
             }
           ] = package["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end
end
