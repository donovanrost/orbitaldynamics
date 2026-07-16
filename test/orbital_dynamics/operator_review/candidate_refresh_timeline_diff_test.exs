defmodule OrbitalDynamics.OperatorReview.CandidateRefreshTimelineDiffTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{OperatorReview, Schema}

  test "candidate refresh source timeline diff reports become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:source_timeline_diff_review:001",
      "source_timeline_diff_report" => [
        %{
          "schema_contract" => "timeline_diff_report.v1",
          "source" => "mission_state.source_timeline_diff_report",
          "rows" => [
            %{
              "id" => "timeline_diff:timeline:obs_1",
              "rank" => 1,
              "timeline_id" => "timeline:obs_1",
              "diff_status" => "changed",
              "source_activity_id" => "obs_1",
              "replacement_activity_id" => "obs_1b",
              "source_activity_type" => "observe",
              "replacement_activity_type" => "observe",
              "scenario_id" => "leo_1",
              "source_starts_at_s" => 10.0,
              "source_ends_at_s" => 20.0,
              "replacement_starts_at_s" => 12.0,
              "replacement_ends_at_s" => 22.0,
              "start_delta_s" => 2.0,
              "end_delta_s" => 2.0,
              "source_status" => "approved",
              "replacement_status" => "planned",
              "changed_fields" => ["starts_at_s", "ends_at_s"],
              "requires_operator_review" => true,
              "required_operator_action" => "review_timeline_change",
              "reason" => "replacement timeline changes activity obs_1",
              "source_timeline_identity" => %{"timeline_id" => "timeline:obs_1"},
              "replacement_timeline_identity" => %{"timeline_id" => "timeline:obs_1"}
            },
            %{
              "id" => "timeline_diff:timeline:health_1",
              "timeline_id" => "timeline:health_1",
              "diff_status" => "unchanged",
              "requires_operator_review" => false,
              "required_operator_action" => "none"
            }
          ]
        }
      ]
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:source_timeline_diff_review:001",
             "review_count" => 1,
             "timeline_diff_count" => 1
           } = package

    assert [
             %{
               "review_type" => "timeline_diff_review",
               "source" => "candidate_refresh.source_timeline_diff_report[0].rows",
               "subject_id" => "timeline:obs_1",
               "timeline_id" => "timeline:obs_1",
               "diff_status" => "changed",
               "activity_id" => "obs_1b",
               "source_activity_id" => "obs_1",
               "replacement_activity_id" => "obs_1b",
               "required_operator_action" => "review_timeline_change",
               "operator_action_reason" => "replacement timeline changes activity obs_1",
               "changed_fields" => ["starts_at_s", "ends_at_s"],
               "source_timeline_diff" => %{"timeline_id" => "timeline:obs_1"}
             }
           ] = package["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh result artifact timeline diff reports become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:wrapped_timeline_diff_review:001",
      "result_artifact" => [
        %{
          "schema_contract" => "result_artifact.v1",
          "timeline_diff_report" => %{
            "schema_contract" => "timeline_diff_report.v1",
            "source" => "wrapped.timeline_diff_report",
            "rows" => [
              %{
                "id" => "timeline_diff:timeline:obs_wrapped",
                "rank" => 1,
                "timeline_id" => "timeline:obs_wrapped",
                "diff_status" => "changed",
                "source_activity_id" => "obs_wrapped",
                "replacement_activity_id" => "obs_wrapped_b",
                "source_activity_type" => "observe",
                "replacement_activity_type" => "observe",
                "scenario_id" => "leo_1",
                "source_starts_at_s" => 10.0,
                "source_ends_at_s" => 20.0,
                "replacement_starts_at_s" => 12.0,
                "replacement_ends_at_s" => 22.0,
                "start_delta_s" => 2.0,
                "end_delta_s" => 2.0,
                "source_status" => "approved",
                "replacement_status" => "planned",
                "changed_fields" => ["starts_at_s", "ends_at_s"],
                "requires_operator_review" => true,
                "required_operator_action" => "review_timeline_change",
                "reason" => "replacement timeline changes activity obs_wrapped",
                "source_timeline_identity" => %{"timeline_id" => "timeline:obs_wrapped"},
                "replacement_timeline_identity" => %{
                  "timeline_id" => "timeline:obs_wrapped"
                }
              },
              %{
                "id" => "timeline_diff:timeline:health_wrapped",
                "timeline_id" => "timeline:health_wrapped",
                "diff_status" => "unchanged",
                "requires_operator_review" => false,
                "required_operator_action" => "none"
              }
            ]
          }
        }
      ]
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:wrapped_timeline_diff_review:001",
             "review_count" => 1,
             "timeline_diff_count" => 1
           } = package

    assert [
             %{
               "review_type" => "timeline_diff_review",
               "source" => "candidate_refresh.result_artifact[0].timeline_diff_report.rows",
               "subject_id" => "timeline:obs_wrapped",
               "timeline_id" => "timeline:obs_wrapped",
               "diff_status" => "changed",
               "activity_id" => "obs_wrapped_b",
               "source_activity_id" => "obs_wrapped",
               "replacement_activity_id" => "obs_wrapped_b",
               "required_operator_action" => "review_timeline_change",
               "operator_action_reason" => "replacement timeline changes activity obs_wrapped",
               "changed_fields" => ["starts_at_s", "ends_at_s"],
               "source_timeline_diff" => %{"timeline_id" => "timeline:obs_wrapped"}
             }
           ] = package["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end
end
