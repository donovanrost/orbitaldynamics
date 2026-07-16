defmodule OrbitalDynamics.OperatorReview.CandidateRefreshConstraintTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{OperatorReview, Schema}

  test "candidate refresh source constraint reports become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:source_constraint_review:001",
      "source_constraint_report" => [
        %{
          "schema_contract" => "constraint_report.v1",
          "source" => "mission_state.source_constraint_report",
          "rows" => [
            %{
              "constraint_id" => "minimum_operational_altitude",
              "metric" => "min_altitude_km",
              "operator" => ">=",
              "scenario_id" => "dispersion_1",
              "score" => 0.42,
              "status" => "pass",
              "threshold" => 621.5,
              "value" => 621.92
            },
            %{
              "constraint_id" => "downlink_margin",
              "metric" => "estimated_throughput_mb",
              "operator" => ">=",
              "scenario_id" => "dispersion_2",
              "status" => "warning",
              "threshold" => 120.0,
              "value" => 96.0
            }
          ]
        }
      ]
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:source_constraint_review:001",
             "review_count" => 1,
             "constraint_review_count" => 1
           } = package

    assert [
             %{
               "review_type" => "constraint_review",
               "source" => "candidate_refresh.source_constraint_report[0].rows",
               "subject_id" => "dispersion_2",
               "scenario_id" => "dispersion_2",
               "constraint_id" => "downlink_margin",
               "metric" => "estimated_throughput_mb",
               "constraint_status" => "warning",
               "required_operator_action" => "review_constraint",
               "source_constraint_row" => %{
                 "constraint_id" => "downlink_margin",
                 "status" => "warning"
               }
             }
           ] = package["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh result artifact constraint reports become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:wrapped_constraint_review:001",
      "source_result_artifact" => %{
        "schema_contract" => "result_artifact.v1",
        "constraint_report" => %{
          "schema_contract" => "constraint_report.v1",
          "source" => "wrapped.constraint_report",
          "rows" => [
            %{
              "constraint_id" => "minimum_operational_altitude",
              "metric" => "min_altitude_km",
              "operator" => ">=",
              "scenario_id" => "dispersion_1",
              "score" => 0.42,
              "status" => "pass",
              "threshold" => 621.5,
              "value" => 621.92
            },
            %{
              "constraint_id" => "downlink_margin",
              "metric" => "estimated_throughput_mb",
              "operator" => ">=",
              "scenario_id" => "dispersion_2",
              "status" => "warning",
              "threshold" => 120.0,
              "value" => 96.0
            }
          ]
        }
      }
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:wrapped_constraint_review:001",
             "review_count" => 1,
             "constraint_review_count" => 1
           } = package

    assert [
             %{
               "review_type" => "constraint_review",
               "source" => "candidate_refresh.source_result_artifact.constraint_report.rows",
               "subject_id" => "dispersion_2",
               "scenario_id" => "dispersion_2",
               "constraint_id" => "downlink_margin",
               "metric" => "estimated_throughput_mb",
               "constraint_status" => "warning",
               "required_operator_action" => "review_constraint",
               "source_constraint_row" => %{
                 "constraint_id" => "downlink_margin",
                 "status" => "warning"
               }
             }
           ] = package["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end
end
