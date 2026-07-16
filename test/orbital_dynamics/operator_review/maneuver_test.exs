defmodule OrbitalDynamics.OperatorReview.ManeuverTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{OperatorReview, Schema}

  test "builds review package from maneuver review rows" do
    report = %{
      "schema_contract" => "maneuver_review_report.v1",
      "model" => "artifact_only_maneuver_review_report",
      "source" => "maneuver_recommendations",
      "source_artifact_id" => "result:leo_1",
      "maneuver_count" => 1,
      "review_required_count" => 1,
      "total_delta_v_km_s" => 0.01,
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
          "maneuver_success_factor_source" => "realized_activity.completed_fraction",
          "approval_status" => "operator_review_required",
          "approval_rule_matches" => [
            %{
              "rule_id" => "maneuver_timing_authority_review",
              "classification" => "operator_review_required"
            }
          ],
          "policy_decision" => %{
            "schema_contract" => "policy_decision.v1",
            "classification" => "operator_review_required",
            "policy_bundle_id" => "maneuver_authority_v1",
            "escalations" => [
              %{"rule_id" => "unmatched_maneuver_rule", "escalation_queue" => "ignore_queue"},
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
      ],
      "assumptions" => %{"boundary" => "review_only_no_command_execution"}
    }

    package = OperatorReview.from_maneuver_review_report(report)

    assert OrbitalDynamics.operator_review_package(report) == package

    assert %{
             "source_artifact_type" => "maneuver_review_report.v1",
             "source_artifact_id" => "result:leo_1",
             "review_count" => 1,
             "maneuver_review_count" => 1
           } = package

    assert %{
             "review_type" => "maneuver_review",
             "subject_id" => "trim_burn",
             "maneuver_id" => "trim_burn",
             "scenario_id" => "leo_1",
             "maneuver_type" => "impulsive_burn",
             "delta_v_magnitude_km_s" => 0.01,
             "maneuver_success_factor" => 0.4,
             "maneuver_success_factor_source" => "realized_activity.completed_fraction",
             "required_operator_action" => "review_maneuver_recommendation",
             "execution_boundary" => "recommendation_only_no_command_execution",
             "approval_rule_matches" => [
               %{"rule_id" => "maneuver_timing_authority_review"}
             ],
             "escalation_level" => "flight_director",
             "escalation_queue" => "maneuver_authority",
             "escalation_role" => "flight_dynamics_lead",
             "required_authority" => "maneuver_authority",
             "sla_s" => 1200,
             "source_policy_decision" => %{
               "policy_bundle_id" => "maneuver_authority_v1"
             },
             "source_policy_escalation" => %{
               "rule_id" => "maneuver_timing_authority_review",
               "escalation_queue" => "maneuver_authority"
             },
             "source_maneuver_review" => %{
               "maneuver_id" => "trim_burn",
               "maneuver_success_factor" => 0.4
             }
           } = List.first(package["rows"])

    assert List.first(package["rows"])["delta_v_km_s"] == [0.0, 0.01, 0.0]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "maneuver review packages reject stale source maneuver evidence" do
    report =
      OrbitalDynamics.maneuver_review_report([
        %{
          "id" => "trim_burn",
          "scenario_id" => "leo_1",
          "type" => "impulsive_burn",
          "epoch_s" => 120.0,
          "frame" => "eci_j2000",
          "delta_v_km_s" => [0.0, 0.01, 0.0],
          "delta_v_magnitude_km_s" => 0.01,
          "maneuver_model" => "impulsive_burns"
        }
      ])

    package =
      report
      |> OperatorReview.from_maneuver_review_report()
      |> update_in(["rows", Access.at(0), "source_maneuver_review"], fn source ->
        Map.put(source, "maneuver_id", "trim_burn_stale")
      end)

    assert {:error, stale_source_report} = Schema.validate_artifact(package)

    assert Enum.any?(
             stale_source_report["errors"],
             &(&1["path"] == "$.rows[0].maneuver_id" and
                 &1["message"] == "must match source_maneuver_review.maneuver_id")
           )
  end

  test "builds standalone maneuver recommendation review package" do
    recommendation = %{
      "schema_contract" => "maneuver_recommendation.v1",
      "id" => "trim_burn",
      "scenario_id" => "ops_checkout",
      "type" => "impulsive_burn",
      "epoch_s" => 180.0,
      "epoch_scale" => "tdb",
      "frame" => "eci_j2000",
      "delta_v_km_s" => [0.0, 0.01, 0.0],
      "delta_v_magnitude_km_s" => 0.01,
      "maneuver_model" => "impulsive_burns",
      "assumptions" => %{
        "execution_boundary" => "recommendation_only_no_command_execution",
        "source" => "trajectory_assumptions"
      }
    }

    package = OperatorReview.from_maneuver_recommendation(recommendation)
    assert OrbitalDynamics.operator_review_package(recommendation) == package

    assert %{
             "source_artifact_type" => "maneuver_recommendation.v1",
             "source_artifact_id" => "trim_burn",
             "review_count" => 1,
             "maneuver_review_count" => 1,
             "rows" => [
               %{
                 "review_type" => "maneuver_review",
                 "source" => "maneuver_recommendation",
                 "maneuver_id" => "trim_burn",
                 "scenario_id" => "ops_checkout",
                 "maneuver_type" => "impulsive_burn",
                 "delta_v_magnitude_km_s" => 0.01,
                 "required_operator_action" => "review_maneuver_recommendation",
                 "execution_boundary" => "recommendation_only_no_command_execution",
                 "source_recommendation" => %{
                   "schema_contract" => "maneuver_recommendation.v1"
                 },
                 "source_maneuver_review" => %{"maneuver_id" => "trim_burn"}
               }
             ]
           } = package

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "maneuver review report and recommendation source ids fall back through defaults" do
    assert %{"source_artifact_id" => "maneuver:report"} =
             OperatorReview.from_maneuver_review_report(%{
               id: :"maneuver:report",
               rows: []
             })

    assert %{"source_artifact_id" => "maneuver:source_artifact"} =
             OperatorReview.from_maneuver_review_report(%{
               source_artifact_id: :"maneuver:source_artifact",
               rows: []
             })

    assert %{"source_artifact_id" => "maneuver:source"} =
             OperatorReview.from_maneuver_review_report(%{
               source: :"maneuver:source",
               rows: []
             })

    assert %{"source_artifact_id" => "maneuver_review_report"} =
             OperatorReview.from_maneuver_review_report(%{rows: []})

    assert %{"source_artifact_id" => "maneuver:recommendation"} =
             OperatorReview.from_maneuver_recommendation(%{
               id: :"maneuver:recommendation"
             })

    assert %{"source_artifact_id" => "maneuver:burn"} =
             OperatorReview.from_maneuver_recommendation(%{
               maneuver_id: :"maneuver:burn"
             })

    assert %{"source_artifact_id" => "maneuver_recommendation"} =
             OperatorReview.from_maneuver_recommendation(%{})
  end

  test "builds standalone maneuver execution delta review package" do
    delta = %{
      "schema_contract" => "maneuver_execution_delta.v1",
      "activity_id" => "trim_burn_1",
      "status" => "completed",
      "epoch_s" => 180.0,
      "delta_v_km_s" => [0.0, 0.01, 0.0],
      "source" => %{"system" => "ops_log", "source_id" => "maneuver_log_1"},
      "quality" => %{"level" => "operator_reported"},
      "provenance" => %{"trust_boundary" => "operator_supplied"}
    }

    package = OperatorReview.from_maneuver_execution_delta(delta)
    assert OrbitalDynamics.operator_review_package(delta) == package

    assert %{
             "source_artifact_type" => "maneuver_execution_delta.v1",
             "source_artifact_id" => "trim_burn_1",
             "review_count" => 1,
             "realized_feedback_count" => 1,
             "rows" => [
               %{
                 "review_type" => "realized_feedback",
                 "source" => "maneuver_execution_delta",
                 "activity_id" => "trim_burn_1",
                 "feedback_status" => "realized_only",
                 "realized_status" => "completed",
                 "realized_type" => "impulsive_burn",
                 "realized_trust_boundary" => "operator_supplied",
                 "realized_provenance" => %{"trust_boundary" => "operator_supplied"},
                 "required_operator_action" => "review_unplanned_realization",
                 "source_feedback" => %{
                   "realized_activity" => %{
                     "schema_contract" => "maneuver_execution_delta.v1"
                   }
                 }
               }
             ]
           } = package

    [row] = package["rows"]

    assert get_in(row, ["source_feedback", "realized_activity", "delta_v_km_s"]) == [
             0.0,
             0.01,
             0.0
           ]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "maneuver execution delta source id falls back through activity id and default" do
    assert %{"source_artifact_id" => "delta_id"} =
             OperatorReview.from_maneuver_execution_delta(%{
               id: :delta_id,
               activity_id: :activity_id,
               status: :completed
             })

    assert %{"source_artifact_id" => "maneuver_execution_delta"} =
             OperatorReview.from_maneuver_execution_delta(%{status: :completed})
  end
end
