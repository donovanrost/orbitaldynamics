defmodule OrbitalDynamics.OperatorReview.CandidateRefreshManeuverReviewTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{OperatorReview, Schema}

  test "candidate refresh source maneuver review reports become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:source_maneuver_review:001",
      "source_maneuver_review_report" => [
        %{
          "schema_contract" => "maneuver_review_report.v1",
          "model" => "artifact_only_maneuver_review_report",
          "source" => "mission_state.source_maneuver_review_report",
          "rows" => [
            %{
              "id" => "maneuver_review:leo_1:trim_burn",
              "rank" => 1,
              "maneuver_id" => "trim_burn",
              "scenario_id" => "leo_1",
              "maneuver_type" => "impulsive_burn",
              "epoch_s" => 120.0,
              "epoch_scale" => "tdb",
              "frame" => "eci_j2000",
              "delta_v_km_s" => [0.0, 0.01, 0.0],
              "delta_v_magnitude_km_s" => 0.01,
              "maneuver_model" => "impulsive_burns",
              "maneuver_success_factor" => 0.4,
              "maneuver_success_factor_source" =>
                "source_maneuver_review_report.operational_feedback",
              "approval_status" => "operator_review_required",
              "policy_decision" => %{
                "schema_contract" => "policy_decision.v1",
                "classification" => "operator_review_required",
                "policy_bundle_id" => "maneuver_authority_v1",
                "escalations" => [
                  %{
                    "rule_id" => "maneuver_timing_authority_review",
                    "escalation_level" => "flight_director",
                    "escalation_queue" => "maneuver_authority",
                    "escalation_role" => "flight_dynamics_lead",
                    "required_authority" => "maneuver_authority",
                    "sla_s" => 1200
                  }
                ]
              },
              "required_operator_action" => "review_maneuver_recommendation",
              "reason" => "review impulsive_burn maneuver at 120.0s with 0.01 km/s delta-v",
              "execution_boundary" => "recommendation_only_no_command_execution",
              "source_recommendation" => %{
                "schema_contract" => "maneuver_recommendation.v1",
                "id" => "trim_burn"
              }
            }
          ]
        }
      ]
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:source_maneuver_review:001",
             "review_count" => 1,
             "maneuver_review_count" => 1
           } = package

    assert [
             %{
               "review_type" => "maneuver_review",
               "source" => "candidate_refresh.source_maneuver_review_report[0].rows",
               "subject_id" => "trim_burn",
               "maneuver_id" => "trim_burn",
               "scenario_id" => "leo_1",
               "maneuver_type" => "impulsive_burn",
               "delta_v_magnitude_km_s" => 0.01,
               "maneuver_success_factor" => 0.4,
               "required_operator_action" => "review_maneuver_recommendation",
               "execution_boundary" => "recommendation_only_no_command_execution",
               "policy_bundle_id" => "maneuver_authority_v1",
               "escalation_queue" => "maneuver_authority",
               "source_maneuver_review" => %{
                 "maneuver_id" => "trim_burn",
                 "maneuver_success_factor" => 0.4
               }
             }
           ] = package["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh result artifact maneuver review reports become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:wrapped_maneuver_review:001",
      "result_artifact" => [
        %{
          "schema_contract" => "result_artifact.v1",
          "maneuver_review_report" => %{
            "schema_contract" => "maneuver_review_report.v1",
            "model" => "artifact_only_maneuver_review_report",
            "source" => "wrapped.maneuver_review_report",
            "rows" => [
              %{
                "id" => "maneuver_review:leo_1:wrapped_trim_burn",
                "rank" => 1,
                "maneuver_id" => "wrapped_trim_burn",
                "scenario_id" => "leo_1",
                "maneuver_type" => "impulsive_burn",
                "epoch_s" => 120.0,
                "epoch_scale" => "tdb",
                "frame" => "eci_j2000",
                "delta_v_km_s" => [0.0, 0.01, 0.0],
                "delta_v_magnitude_km_s" => 0.01,
                "maneuver_model" => "impulsive_burns",
                "maneuver_success_factor" => 0.4,
                "maneuver_success_factor_source" =>
                  "source_maneuver_review_report.operational_feedback",
                "approval_status" => "operator_review_required",
                "policy_decision" => %{
                  "schema_contract" => "policy_decision.v1",
                  "classification" => "operator_review_required",
                  "policy_bundle_id" => "maneuver_authority_v1",
                  "escalations" => [
                    %{
                      "rule_id" => "maneuver_timing_authority_review",
                      "escalation_level" => "flight_director",
                      "escalation_queue" => "maneuver_authority",
                      "escalation_role" => "flight_dynamics_lead",
                      "required_authority" => "maneuver_authority",
                      "sla_s" => 1200
                    }
                  ]
                },
                "required_operator_action" => "review_maneuver_recommendation",
                "reason" => "review impulsive_burn maneuver at 120.0s with 0.01 km/s delta-v",
                "execution_boundary" => "recommendation_only_no_command_execution",
                "source_recommendation" => %{
                  "schema_contract" => "maneuver_recommendation.v1",
                  "id" => "wrapped_trim_burn"
                }
              }
            ]
          }
        }
      ]
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:wrapped_maneuver_review:001",
             "review_count" => 1,
             "maneuver_review_count" => 1
           } = package

    assert [
             %{
               "review_type" => "maneuver_review",
               "source" => "candidate_refresh.result_artifact[0].maneuver_review_report.rows",
               "subject_id" => "wrapped_trim_burn",
               "maneuver_id" => "wrapped_trim_burn",
               "scenario_id" => "leo_1",
               "maneuver_type" => "impulsive_burn",
               "delta_v_magnitude_km_s" => 0.01,
               "maneuver_success_factor" => 0.4,
               "required_operator_action" => "review_maneuver_recommendation",
               "execution_boundary" => "recommendation_only_no_command_execution",
               "policy_bundle_id" => "maneuver_authority_v1",
               "escalation_queue" => "maneuver_authority",
               "source_maneuver_review" => %{
                 "maneuver_id" => "wrapped_trim_burn",
                 "maneuver_success_factor" => 0.4
               }
             }
           ] = package["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end
end
