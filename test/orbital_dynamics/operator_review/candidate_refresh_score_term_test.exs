defmodule OrbitalDynamics.OperatorReview.CandidateRefreshScoreTermTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{OperatorReview, Schema}

  test "candidate refresh source score term reports become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:source_score_term_review:001",
      "source_score_term_report" => [
        %{
          "schema_contract" => "score_term_report.v1",
          "source" => "mission_state.source_score_term_report",
          "rows" => [
            %{
              "id" => "score_term:leo_1:1:target_value",
              "rank" => 1,
              "scenario_id" => "leo_1",
              "term_key" => "target_value",
              "value" => 120.0,
              "timeline_score" => 140.0,
              "selected" => true
            }
          ]
        }
      ]
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:source_score_term_review:001",
             "review_count" => 1,
             "score_term_review_count" => 1
           } = package

    assert [
             %{
               "review_type" => "score_term_review",
               "source" => "candidate_refresh.source_score_term_report[0].rows",
               "subject_id" => "score_term:leo_1:1:target_value",
               "scenario_id" => "leo_1",
               "term_key" => "target_value",
               "value" => 120.0,
               "timeline_score" => 140.0,
               "selected" => true,
               "required_operator_action" => "review_score_term",
               "source_score_term" => %{"term_key" => "target_value"}
             }
           ] = package["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh result artifact score term reports become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:wrapped_score_term_review:001",
      "source_result_artifact" => %{
        "schema_contract" => "result_artifact.v1",
        "score_term_report" => %{
          "schema_contract" => "score_term_report.v1",
          "source" => "wrapped.score_term_report",
          "rows" => [
            %{
              "id" => "score_term:leo_1:1:target_value",
              "rank" => 1,
              "scenario_id" => "leo_1",
              "term_key" => "target_value",
              "value" => 120.0,
              "timeline_score" => 140.0,
              "selected" => true
            }
          ]
        }
      }
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:wrapped_score_term_review:001",
             "review_count" => 1,
             "score_term_review_count" => 1
           } = package

    assert [
             %{
               "review_type" => "score_term_review",
               "source" => "candidate_refresh.source_result_artifact.score_term_report.rows",
               "subject_id" => "score_term:leo_1:1:target_value",
               "scenario_id" => "leo_1",
               "term_key" => "target_value",
               "value" => 120.0,
               "timeline_score" => 140.0,
               "selected" => true,
               "required_operator_action" => "review_score_term",
               "source_score_term" => %{"term_key" => "target_value"}
             }
           ] = package["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end
end
