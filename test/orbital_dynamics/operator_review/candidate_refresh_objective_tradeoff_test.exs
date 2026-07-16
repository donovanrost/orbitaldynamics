defmodule OrbitalDynamics.OperatorReview.CandidateRefreshObjectiveTradeoffTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{OperatorReview, Schema}

  test "candidate refresh source objective tradeoff reports become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:source_objective_tradeoff_review:001",
      "source_objective_tradeoff_report" => [
        %{
          "schema_contract" => "objective_tradeoff_report.v1",
          "source" => "mission_state.source_objective_tradeoff_report",
          "tradeoffs" => [
            %{
              "rank" => 1,
              "scenario_id" => "leo_1",
              "score" => 140.0,
              "score_delta_from_selected" => 0.0,
              "activity_count" => 2,
              "selected_observation_count" => 1,
              "selected_contact_count" => 1,
              "score_terms" => %{"target_value" => 150.0},
              "activity_ids" => ["leo_1_observe_target_a_1", "leo_1_downlink_1"]
            }
          ]
        }
      ]
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:source_objective_tradeoff_review:001",
             "review_count" => 1,
             "objective_tradeoff_review_count" => 1
           } = package

    assert [
             %{
               "review_type" => "objective_tradeoff_review",
               "source" => "candidate_refresh.source_objective_tradeoff_report[0].tradeoffs",
               "subject_id" => "leo_1",
               "scenario_id" => "leo_1",
               "score" => 140.0,
               "activity_count" => 2,
               "selected_observation_count" => 1,
               "selected_contact_count" => 1,
               "score_terms" => %{"target_value" => 150.0},
               "activity_ids" => ["leo_1_observe_target_a_1", "leo_1_downlink_1"],
               "required_operator_action" => "review_objective_tradeoff",
               "source_objective_tradeoff" => %{"scenario_id" => "leo_1"}
             } = row
           ] = package["rows"]

    assert row["score_delta_from_selected"] == 0.0

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh result artifact objective tradeoff reports become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:wrapped_objective_tradeoff_review:001",
      "source_result_artifact" => %{
        "schema_contract" => "result_artifact.v1",
        "objective_tradeoff_report" => %{
          "schema_contract" => "objective_tradeoff_report.v1",
          "source" => "wrapped.objective_tradeoff_report",
          "tradeoffs" => [
            %{
              "rank" => 1,
              "scenario_id" => "leo_1",
              "score" => 140.0,
              "score_delta_from_selected" => 0.0,
              "activity_count" => 2,
              "selected_observation_count" => 1,
              "selected_contact_count" => 1,
              "score_terms" => %{"target_value" => 150.0},
              "activity_ids" => ["leo_1_observe_target_a_1", "leo_1_downlink_1"]
            }
          ]
        }
      }
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:wrapped_objective_tradeoff_review:001",
             "review_count" => 1,
             "objective_tradeoff_review_count" => 1
           } = package

    assert [
             %{
               "review_type" => "objective_tradeoff_review",
               "source" =>
                 "candidate_refresh.source_result_artifact.objective_tradeoff_report.tradeoffs",
               "subject_id" => "leo_1",
               "scenario_id" => "leo_1",
               "score" => 140.0,
               "activity_count" => 2,
               "selected_observation_count" => 1,
               "selected_contact_count" => 1,
               "score_terms" => %{"target_value" => 150.0},
               "activity_ids" => ["leo_1_observe_target_a_1", "leo_1_downlink_1"],
               "required_operator_action" => "review_objective_tradeoff",
               "source_objective_tradeoff" => %{"scenario_id" => "leo_1"}
             } = row
           ] = package["rows"]

    assert row["score_delta_from_selected"] == 0.0

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end
end
