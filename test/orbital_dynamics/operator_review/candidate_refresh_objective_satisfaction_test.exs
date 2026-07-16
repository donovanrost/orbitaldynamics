defmodule OrbitalDynamics.OperatorReview.CandidateRefreshObjectiveSatisfactionTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{OperatorReview, Schema}

  test "candidate refresh source objective satisfaction reports become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:source_objective_satisfaction_review:001",
      "source_objective_satisfaction_report" => [
        %{
          "schema_contract" => "objective_satisfaction_report.v1",
          "source" => "mission_state.source_objective_satisfaction_report",
          "rows" => [
            %{
              "id" => "objective:target_coverage",
              "objective" => "target_coverage",
              "status" => "selected",
              "required_count" => 1,
              "candidate_count" => 1,
              "selected_count" => 1,
              "satisfied_count" => 1,
              "selected_activity_ids" => ["obs_target_a"]
            },
            %{
              "id" => "objective:downlink_completion",
              "objective" => "downlink_completion",
              "status" => "unmet",
              "required_downlink_mb" => 150.0,
              "candidate_downlink_mb" => 160.0,
              "candidate_count" => 1,
              "selected_count" => 0,
              "satisfied_count" => 0,
              "selected_downlink_mb" => 0.0,
              "satisfied_downlink_mb" => 0.0,
              "selected_contact_ids" => []
            }
          ]
        }
      ]
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:source_objective_satisfaction_review:001",
             "review_count" => 1,
             "objective_satisfaction_review_count" => 1
           } = package

    assert [
             %{
               "review_type" => "objective_satisfaction_review",
               "source" => "candidate_refresh.source_objective_satisfaction_report[0].rows",
               "subject_id" => "objective:downlink_completion",
               "objective" => "downlink_completion",
               "objective_status" => "unmet",
               "required_downlink_mb" => 150.0,
               "candidate_downlink_mb" => 160.0,
               "required_operator_action" => "review_objective_satisfaction",
               "source_objective_satisfaction" => %{
                 "objective" => "downlink_completion",
                 "status" => "unmet"
               }
             } = row
           ] = package["rows"]

    assert row["selected_downlink_mb"] == 0.0

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh result artifact objective satisfaction reports become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:wrapped_objective_satisfaction_review:001",
      "source_result_artifact" => %{
        "schema_contract" => "result_artifact.v1",
        "objective_satisfaction_report" => %{
          "schema_contract" => "objective_satisfaction_report.v1",
          "source" => "wrapped.objective_satisfaction_report",
          "rows" => [
            %{
              "id" => "objective:target_coverage",
              "objective" => "target_coverage",
              "status" => "selected",
              "required_count" => 1,
              "candidate_count" => 1,
              "selected_count" => 1,
              "satisfied_count" => 1,
              "selected_activity_ids" => ["obs_target_a"]
            },
            %{
              "id" => "objective:downlink_completion",
              "objective" => "downlink_completion",
              "status" => "unmet",
              "required_downlink_mb" => 150.0,
              "candidate_downlink_mb" => 160.0,
              "candidate_count" => 1,
              "selected_count" => 0,
              "satisfied_count" => 0,
              "selected_downlink_mb" => 0.0,
              "satisfied_downlink_mb" => 0.0,
              "selected_contact_ids" => []
            }
          ]
        }
      }
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" =>
               "candidate_refresh:wrapped_objective_satisfaction_review:001",
             "review_count" => 1,
             "objective_satisfaction_review_count" => 1
           } = package

    assert [
             %{
               "review_type" => "objective_satisfaction_review",
               "source" =>
                 "candidate_refresh.source_result_artifact.objective_satisfaction_report.rows",
               "subject_id" => "objective:downlink_completion",
               "objective" => "downlink_completion",
               "objective_status" => "unmet",
               "required_downlink_mb" => 150.0,
               "candidate_downlink_mb" => 160.0,
               "required_operator_action" => "review_objective_satisfaction",
               "source_objective_satisfaction" => %{
                 "objective" => "downlink_completion",
                 "status" => "unmet"
               }
             } = row
           ] = package["rows"]

    assert row["selected_downlink_mb"] == 0.0

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end
end
