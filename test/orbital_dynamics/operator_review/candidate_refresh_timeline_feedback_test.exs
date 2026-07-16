defmodule OrbitalDynamics.OperatorReview.CandidateRefreshTimelineFeedbackTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{OperatorReview, Schema}

  test "candidate refresh source timeline feedback reports become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:timeline_feedback_review:001",
      "source_timeline_feedback_report" => %{
        "schema_contract" => "timeline_feedback_report.v1",
        "rows" => [
          %{
            "activity_id" => "dl_live_feedback",
            "status" => "matched",
            "feedback_kind" => "contact",
            "match_strategy" => "timeline_activity_id",
            "planned_type" => "downlink",
            "planned_status" => "approved",
            "planned_timeline_id" => "timeline:leo_1:downlink:dl_live_feedback",
            "timeline_identity" => %{
              "timeline_id" => "timeline:leo_1:downlink:dl_live_feedback",
              "activity_id" => "dl_live_feedback"
            },
            "realized_timeline_id" => "timeline:leo_1:downlink:dl_live_feedback",
            "realized_activity_id" => "provider_contact_42",
            "realized_status" => "failed",
            "realized_source" => %{"adapter" => "cadence_feedback_adapter"},
            "realized_provider" => "cadence",
            "realized_source_quality" => "declared",
            "realized_adapter" => "cadence_feedback_adapter",
            "realized_adapter_version" => "2026.05.31",
            "realized_external_id" => "cadence:contact:42",
            "realized_schema_contract" => "cadence_contact_feedback.v1",
            "realized_trust_boundary" => "cadence_feedback_adapter",
            "realized_received_at" => "2026-05-31T00:00:00Z",
            "realized_ingested_at" => "2026-05-31T00:01:00Z",
            "realized_provenance" => %{"source" => "cadence"},
            "station_reservation_id" => "reservation:equator_prime:dl_live_feedback",
            "station_reservation_status" => "held",
            "station_reservation_match_status" => "matched"
          },
          %{
            "activity_id" => "dl_missing_feedback",
            "status" => "planned_only",
            "feedback_kind" => "contact",
            "planned_type" => "downlink"
          }
        ]
      }
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:timeline_feedback_review:001",
             "review_count" => 1,
             "realized_feedback_count" => 1,
             "required_operator_action_counts" => %{"review_contact_exception" => 1}
           } = package

    assert [
             %{
               "review_type" => "realized_feedback",
               "source" => "candidate_refresh.source_timeline_feedback_report.rows",
               "subject_id" => "dl_live_feedback",
               "activity_id" => "dl_live_feedback",
               "activity_type" => "downlink",
               "required_operator_action" => "review_contact_exception",
               "approval_status" => "operator_review_required",
               "feedback_status" => "matched",
               "feedback_kind" => "contact",
               "match_strategy" => "timeline_activity_id",
               "planned_timeline_id" => "timeline:leo_1:downlink:dl_live_feedback",
               "timeline_identity" => %{
                 "timeline_id" => "timeline:leo_1:downlink:dl_live_feedback",
                 "activity_id" => "dl_live_feedback"
               },
               "realized_timeline_id" => "timeline:leo_1:downlink:dl_live_feedback",
               "realized_activity_id" => "provider_contact_42",
               "realized_status" => "failed",
               "realized_source" => %{"adapter" => "cadence_feedback_adapter"},
               "realized_provider" => "cadence",
               "realized_source_quality" => "declared",
               "realized_adapter" => "cadence_feedback_adapter",
               "realized_adapter_version" => "2026.05.31",
               "realized_external_id" => "cadence:contact:42",
               "realized_schema_contract" => "cadence_contact_feedback.v1",
               "realized_trust_boundary" => "cadence_feedback_adapter",
               "realized_received_at" => "2026-05-31T00:00:00Z",
               "realized_ingested_at" => "2026-05-31T00:01:00Z",
               "realized_provenance" => %{"source" => "cadence"},
               "station_reservation_id" => "reservation:equator_prime:dl_live_feedback",
               "station_reservation_status" => "held",
               "station_reservation_match_status" => "matched",
               "source_feedback" => %{
                 "activity_id" => "dl_live_feedback",
                 "realized_activity_id" => "provider_contact_42"
               }
             }
           ] = package["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh result artifact timeline feedback reports become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:wrapped_timeline_feedback_review:001",
      "source_result_artifact" => %{
        "schema_contract" => "result_artifact.v1",
        "timeline_feedback_report" => %{
          "schema_contract" => "timeline_feedback_report.v1",
          "rows" => [
            %{
              "activity_id" => "dl_wrapped_feedback",
              "status" => "matched",
              "feedback_kind" => "contact",
              "match_strategy" => "timeline_activity_id",
              "planned_type" => "downlink",
              "planned_status" => "approved",
              "planned_timeline_id" => "timeline:leo_1:downlink:dl_wrapped_feedback",
              "timeline_identity" => %{
                "timeline_id" => "timeline:leo_1:downlink:dl_wrapped_feedback",
                "activity_id" => "dl_wrapped_feedback"
              },
              "realized_timeline_id" => "timeline:leo_1:downlink:dl_wrapped_feedback",
              "realized_activity_id" => "provider_contact_42",
              "realized_status" => "failed",
              "realized_source" => %{"adapter" => "cadence_feedback_adapter"},
              "realized_provider" => "cadence",
              "realized_source_quality" => "declared",
              "realized_adapter" => "cadence_feedback_adapter",
              "realized_adapter_version" => "2026.05.31",
              "realized_external_id" => "cadence:contact:42",
              "realized_schema_contract" => "cadence_contact_feedback.v1",
              "realized_trust_boundary" => "cadence_feedback_adapter",
              "realized_received_at" => "2026-05-31T00:00:00Z",
              "realized_ingested_at" => "2026-05-31T00:01:00Z",
              "realized_provenance" => %{"source" => "cadence"},
              "station_reservation_id" => "reservation:equator_prime:dl_wrapped_feedback",
              "station_reservation_status" => "held",
              "station_reservation_match_status" => "matched"
            },
            %{
              "activity_id" => "dl_missing_feedback",
              "status" => "planned_only",
              "feedback_kind" => "contact",
              "planned_type" => "downlink"
            }
          ]
        }
      }
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:wrapped_timeline_feedback_review:001",
             "review_count" => 1,
             "realized_feedback_count" => 1,
             "required_operator_action_counts" => %{"review_contact_exception" => 1}
           } = package

    assert [
             %{
               "review_type" => "realized_feedback",
               "source" =>
                 "candidate_refresh.source_result_artifact.timeline_feedback_report.rows",
               "subject_id" => "dl_wrapped_feedback",
               "activity_id" => "dl_wrapped_feedback",
               "activity_type" => "downlink",
               "required_operator_action" => "review_contact_exception",
               "approval_status" => "operator_review_required",
               "feedback_status" => "matched",
               "feedback_kind" => "contact",
               "match_strategy" => "timeline_activity_id",
               "planned_timeline_id" => "timeline:leo_1:downlink:dl_wrapped_feedback",
               "timeline_identity" => %{
                 "timeline_id" => "timeline:leo_1:downlink:dl_wrapped_feedback",
                 "activity_id" => "dl_wrapped_feedback"
               },
               "realized_timeline_id" => "timeline:leo_1:downlink:dl_wrapped_feedback",
               "realized_activity_id" => "provider_contact_42",
               "realized_status" => "failed",
               "realized_source" => %{"adapter" => "cadence_feedback_adapter"},
               "realized_provider" => "cadence",
               "realized_source_quality" => "declared",
               "realized_adapter" => "cadence_feedback_adapter",
               "realized_adapter_version" => "2026.05.31",
               "realized_external_id" => "cadence:contact:42",
               "realized_schema_contract" => "cadence_contact_feedback.v1",
               "realized_trust_boundary" => "cadence_feedback_adapter",
               "realized_received_at" => "2026-05-31T00:00:00Z",
               "realized_ingested_at" => "2026-05-31T00:01:00Z",
               "realized_provenance" => %{"source" => "cadence"},
               "station_reservation_id" => "reservation:equator_prime:dl_wrapped_feedback",
               "station_reservation_status" => "held",
               "station_reservation_match_status" => "matched",
               "source_feedback" => %{
                 "activity_id" => "dl_wrapped_feedback",
                 "realized_activity_id" => "provider_contact_42"
               }
             }
           ] = package["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end
end
