defmodule OrbitalDynamics.ManeuverReviewTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CadenceImport, ManeuverReview, OperatorReview, Schema}

  test "declares artifact-only maneuver review capabilities" do
    assert %{
             artifact_contract: "maneuver_review_report.v1",
             validation_level: :artifact_contract,
             source_contract: "maneuver_recommendation.v1",
             row_semantics: row_semantics,
             known_limits: known_limits
           } = ManeuverReview.capabilities()

    assert :required_operator_action in row_semantics
    assert :source_recommendation in row_semantics
    assert :execution_uncertainty in row_semantics
    assert :maneuver_success_factor in row_semantics
    assert :invalid_maneuver_recommendation_review in row_semantics
    assert :no_command_execution in known_limits
    assert :no_schedule_mutation in known_limits
    assert :uncertainty_is_review_metadata_not_execution_model in known_limits
  end

  test "builds maneuver review report rows from recommendations" do
    recommendations = [
      %{
        schema_contract: "maneuver_recommendation.v1",
        id: :trim_burn,
        scenario_id: :leo_1,
        type: :impulsive_burn,
        epoch_s: 120.0,
        epoch_scale: :tdb,
        frame: :eci_j2000,
        delta_v_km_s: [0.0, 0.01, 0.0],
        delta_v_magnitude_km_s: 0.01,
        maneuver_model: :impulsive_burns,
        maneuver_success_factor: 0.85,
        maneuver_success_factor_source: :preburn_confidence_model,
        execution_uncertainty: %{
          timing_3sigma_s: 2.5,
          delta_v_3sigma_km_s: [0.0, 0.001, 0.0],
          source: :operator_estimate
        },
        assumptions: %{execution_boundary: :recommendation_only_no_command_execution}
      },
      %{
        "schema_contract" => "maneuver_recommendation.v1",
        "id" => "trim_burn_2",
        "scenario_id" => "leo_1",
        "type" => "impulsive_burn",
        "epoch_s" => 240.0,
        "frame" => "eci_j2000",
        "delta_v_km_s" => [0.0, 0.02, 0.0],
        "delta_v_magnitude_km_s" => 0.02,
        "maneuver_model" => "impulsive_burns",
        "assumptions" => %{"execution_boundary" => "recommendation_only_no_command_execution"}
      }
    ]

    report =
      ManeuverReview.report(recommendations,
        source: "test.maneuver_recommendations",
        source_artifact_id: "result:leo_1"
      )

    assert %{
             "schema_contract" => "maneuver_review_report.v1",
             "source" => "test.maneuver_recommendations",
             "source_artifact_id" => "result:leo_1",
             "maneuver_count" => 2,
             "review_required_count" => 2,
             "execution_uncertainty_declared_count" => 1,
             "execution_uncertainty_missing_count" => 1,
             "total_delta_v_km_s" => 0.03,
             "max_timing_3sigma_s" => 2.5,
             "max_delta_v_3sigma_magnitude_km_s" => max_delta_v_uncertainty,
             "total_delta_v_3sigma_magnitude_km_s" => total_delta_v_uncertainty,
             "model_limits" => model_limits
           } = report

    assert_in_delta max_delta_v_uncertainty, 0.001, 1.0e-12
    assert_in_delta total_delta_v_uncertainty, 0.001, 1.0e-12

    expected_model_limits =
      ManeuverReview.capabilities()
      |> Map.fetch!(:known_limits)
      |> Enum.map(&to_string/1)

    assert model_limits == expected_model_limits

    assert "no_command_execution" in model_limits
    assert "no_schedule_mutation" in model_limits
    assert "uncertainty_is_review_metadata_not_execution_model" in model_limits

    assert [
             %{
               "id" => "maneuver_review:leo_1:trim_burn",
               "rank" => 1,
               "maneuver_id" => "trim_burn",
               "scenario_id" => "leo_1",
               "maneuver_type" => "impulsive_burn",
               "required_operator_action" => "review_maneuver_recommendation",
               "approval_status" => "operator_review_required",
               "execution_boundary" => "recommendation_only_no_command_execution",
               "execution_uncertainty_status" => "declared",
               "execution_uncertainty" => %{
                 "timing_3sigma_s" => 2.5,
                 "source" => "operator_estimate"
               },
               "maneuver_success_factor" => 0.85,
               "maneuver_success_factor_source" => "preburn_confidence_model",
               "timing_3sigma_s" => 2.5,
               "execution_uncertainty_source" => "operator_estimate",
               "source_recommendation" => %{"id" => "trim_burn"}
             } = first_row,
             %{
               "rank" => 2,
               "maneuver_id" => "trim_burn_2",
               "execution_uncertainty_status" => "missing"
             }
           ] = report["rows"]

    assert get_in(first_row, ["execution_uncertainty", "delta_v_3sigma_km_s"]) == [
             0.0,
             0.001,
             0.0
           ]

    assert first_row["delta_v_3sigma_km_s"] == [0.0, 0.001, 0.0]
    assert_in_delta first_row["delta_v_3sigma_magnitude_km_s"], 0.001, 1.0e-12

    assert {:ok, %{"schema_contract" => "maneuver_review_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "classifies maneuver review rows with approval policy" do
    report =
      ManeuverReview.report(
        [
          %{
            "schema_contract" => "maneuver_recommendation.v1",
            "id" => "trim_burn",
            "scenario_id" => "leo_1",
            "type" => "impulsive_burn",
            "epoch_s" => 120.0,
            "frame" => "eci_j2000",
            "delta_v_km_s" => [0.0, 0.01, 0.0],
            "delta_v_magnitude_km_s" => 0.01,
            "maneuver_model" => "impulsive_burns",
            "assumptions" => %{
              "execution_uncertainty" => %{
                "timing_3sigma_s" => 1.5,
                "delta_v_3sigma_km_s" => [0.0001, 0.0002, 0.0002]
              }
            }
          }
        ],
        approval_policy: %{policy_bundle_id: "maneuver_authority_v1"}
      )

    assert [
             %{
               "approval_status" => "operator_review_required",
               "approval_requirements" => [
                 %{
                   "requirement_type" => "maneuver_authority_review",
                   "policy_classification" => "operator_review_required",
                   "activity_context" => %{
                     "execution_uncertainty_status" => "declared",
                     "timing_3sigma_s" => 1.5,
                     "delta_v_3sigma_km_s" => [0.0001, 0.0002, 0.0002],
                     "delta_v_3sigma_magnitude_km_s" => magnitude
                   }
                 }
               ],
               "approval_rule_matches" => rule_matches,
               "policy_decision" => %{
                 "schema_contract" => "policy_decision.v1",
                 "policy_bundle_id" => "maneuver_authority_v1"
               }
             }
           ] = report["rows"]

    assert_in_delta magnitude, 0.0003, 1.0e-12

    assert Enum.any?(
             rule_matches,
             &(&1["rule_id"] == "maneuver_timing_authority_review" and
                 &1["requirement_type"] == "maneuver_authority_review")
           )

    assert Enum.any?(
             rule_matches,
             &(&1["rule_id"] == "impulsive_burn_authority_review" and
                 &1["activity_type"] == "impulsive_burn")
           )

    assert {:ok, %{"schema_contract" => "maneuver_review_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "normalizes clean numeric string maneuver recommendation evidence" do
    report =
      ManeuverReview.report(
        [
          %{
            "schema_contract" => "maneuver_recommendation.v1",
            "id" => "string_burn",
            "scenario_id" => "leo_1",
            "type" => "impulsive_burn",
            "epoch_s" => "120.0",
            "frame" => "eci_j2000",
            "delta_v_km_s" => ["0.0", "0.01", "0.0"],
            "delta_v_magnitude_km_s" => "0.01",
            "maneuver_model" => "impulsive_burns",
            "maneuver_success_factor" => "0.75",
            "maneuver_success_factor_source" => "provider_confidence",
            "execution_uncertainty" => %{
              "timing_3sigma_s" => "2.5",
              "delta_v_3sigma_km_s" => ["0.0", "0.001", "0.0"],
              "source" => "provider"
            }
          }
        ],
        approval_policy: %{
          action_rules: [
            %{
              id: "low_maneuver_confidence_review",
              maneuver_success_factor_max: 0.8,
              classification: "operator_review_required",
              reason: "maneuver confidence requires review"
            }
          ]
        }
      )

    assert %{
             "maneuver_count" => 1,
             "invalid_maneuver_recommendation_count" => 0,
             "execution_uncertainty_declared_count" => 1,
             "total_delta_v_km_s" => 0.01,
             "max_timing_3sigma_s" => 2.5
           } = report

    row = List.first(report["rows"])

    assert Map.take(row, [
             "maneuver_id",
             "scenario_id",
             "epoch_s",
             "delta_v_magnitude_km_s",
             "maneuver_success_factor",
             "timing_3sigma_s",
             "execution_uncertainty_source"
           ]) == %{
             "maneuver_id" => "string_burn",
             "scenario_id" => "leo_1",
             "epoch_s" => 120.0,
             "delta_v_magnitude_km_s" => 0.01,
             "maneuver_success_factor" => 0.75,
             "timing_3sigma_s" => 2.5,
             "execution_uncertainty_source" => "provider"
           }

    assert row["delta_v_km_s"] == [0.0, 0.01, 0.0]
    assert row["delta_v_3sigma_km_s"] == [0.0, 0.001, 0.0]

    assert row["source_recommendation"]["epoch_s"] == 120.0
    assert row["source_recommendation"]["maneuver_success_factor"] == 0.75
    assert row["source_recommendation"]["execution_uncertainty"]["timing_3sigma_s"] == 2.5

    assert [
             %{
               "rule_id" => "low_maneuver_confidence_review",
               "maneuver_success_factor" => 0.75
             }
           ] = row["approval_rule_matches"]

    assert {:ok, %{"schema_contract" => "maneuver_review_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "carries maneuver success confidence into approval policy context" do
    report =
      ManeuverReview.report(
        [
          %{
            "schema_contract" => "maneuver_recommendation.v1",
            "id" => "low_confidence_burn",
            "scenario_id" => "leo_1",
            "type" => "impulsive_burn",
            "epoch_s" => 120.0,
            "frame" => "eci_j2000",
            "delta_v_km_s" => [0.0, 0.01, 0.0],
            "delta_v_magnitude_km_s" => 0.01,
            "maneuver_model" => "impulsive_burns",
            "maneuver_success_factor" => 0.2,
            "maneuver_success_factor_source" => "realized_activity.completed_fraction"
          }
        ],
        approval_policy: %{
          action_rules: [
            %{
              id: "low_maneuver_confidence_block",
              maneuver_success_factor_max: 0.3,
              classification: "blocked_by_policy",
              reason: "low maneuver confidence blocks maneuver review"
            }
          ]
        }
      )

    assert [
             %{
               "approval_status" => "blocked_by_policy",
               "maneuver_success_factor" => 0.2,
               "maneuver_success_factor_source" => "realized_activity.completed_fraction",
               "approval_requirements" => [
                 %{
                   "policy_classification" => "blocked_by_policy",
                   "activity_context" => %{
                     "maneuver_success_factor" => 0.2,
                     "maneuver_success_factor_source" => "realized_activity.completed_fraction"
                   }
                 }
               ],
               "approval_rule_matches" => [
                 %{
                   "rule_id" => "low_maneuver_confidence_block",
                   "maneuver_success_factor" => 0.2,
                   "maneuver_success_factor_source" => "realized_activity.completed_fraction"
                 }
               ]
             }
           ] = report["rows"]

    assert {:ok, %{"schema_contract" => "maneuver_review_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "review gates malformed maneuver optional metadata instead of leaking invalid rows" do
    report =
      ManeuverReview.report(
        [
          %{
            "schema_contract" => "maneuver_recommendation.v1",
            "id" => "bad_success_factor",
            "scenario_id" => "leo_1",
            "type" => "impulsive_burn",
            "epoch_s" => 120.0,
            "frame" => "eci_j2000",
            "delta_v_km_s" => [0.0, 0.01, 0.0],
            "delta_v_magnitude_km_s" => 0.01,
            "maneuver_model" => "impulsive_burns",
            "maneuver_success_factor" => 1.2,
            "maneuver_success_factor_source" => "provider_confidence"
          },
          %{
            "schema_contract" => "maneuver_recommendation.v1",
            "id" => "bad_uncertainty",
            "scenario_id" => "leo_1",
            "type" => "impulsive_burn",
            "epoch_s" => 240.0,
            "frame" => "eci_j2000",
            "delta_v_km_s" => [0.0, 0.02, 0.0],
            "delta_v_magnitude_km_s" => 0.02,
            "maneuver_model" => "impulsive_burns",
            "execution_uncertainty" => %{
              "timing_3sigma_s" => 2.5,
              "delta_v_3sigma_km_s" => [0.0, 0.001],
              "source" => %{"provider" => "nav"}
            }
          },
          %{
            "schema_contract" => "maneuver_recommendation.v1",
            "id" => "bad_delta_v_magnitude",
            "scenario_id" => "leo_1",
            "type" => "impulsive_burn",
            "epoch_s" => 360.0,
            "frame" => "eci_j2000",
            "delta_v_km_s" => [0.0, 0.03, 0.0],
            "delta_v_magnitude_km_s" => "not-a-number",
            "maneuver_model" => "impulsive_burns"
          }
        ],
        source: "test.maneuver_recommendations",
        approval_policy: %{policy_bundle_id: "maneuver_authority_v1"}
      )

    assert %{
             "invalid_maneuver_recommendation_count" => 3,
             "invalid_maneuver_recommendation_ids" => [
               "bad_delta_v_magnitude",
               "bad_success_factor",
               "bad_uncertainty"
             ]
           } = report

    rows_by_id = Map.new(report["rows"], &{&1["maneuver_id"], &1})

    assert %{
             "maneuver_id" => "bad_success_factor",
             "required_operator_action" => "review_invalid_maneuver_recommendation",
             "invalid_maneuver_recommendation" => true,
             "invalid_maneuver_recommendation_reasons" => [
               "invalid_maneuver_success_factor"
             ],
             "approval_requirements" => [
               %{
                 "action" => "review_invalid_maneuver_recommendation",
                 "policy_classification" => "operator_review_required",
                 "activity_context" => %{
                   "invalid_maneuver_recommendation" => true,
                   "invalid_maneuver_recommendation_reasons" => [
                     "invalid_maneuver_success_factor"
                   ]
                 }
               }
             ],
             "approval_rule_matches" => bad_success_factor_rule_matches,
             "policy_decision" => %{"policy_bundle_id" => "maneuver_authority_v1"},
             "source_recommendation" => bad_success_factor_source
           } = rows_by_id["bad_success_factor"]

    refute Map.has_key?(bad_success_factor_source, "maneuver_success_factor")
    assert bad_success_factor_source["maneuver_success_factor_source"] == "provider_confidence"

    assert Enum.any?(
             bad_success_factor_rule_matches,
             &(&1["rule_id"] == "invalid_maneuver_recommendation_review" and
                 &1["action"] == "review_invalid_maneuver_recommendation" and
                 &1["required_authority"] == "maneuver_authority")
           )

    assert %{
             "maneuver_id" => "bad_uncertainty",
             "required_operator_action" => "review_invalid_maneuver_recommendation",
             "invalid_maneuver_recommendation" => true,
             "invalid_maneuver_recommendation_reasons" => ["invalid_execution_uncertainty"],
             "source_recommendation" => %{
               "execution_uncertainty" => %{
                 "delta_v_3sigma_km_s" => invalid_delta_v_3sigma,
                 "source" => %{"provider" => "nav"}
               }
             }
           } = rows_by_id["bad_uncertainty"]

    assert invalid_delta_v_3sigma == [0.0, 0.001]

    assert %{
             "maneuver_id" => "bad_delta_v_magnitude",
             "required_operator_action" => "review_invalid_maneuver_recommendation",
             "invalid_maneuver_recommendation" => true,
             "invalid_maneuver_recommendation_reasons" => ["invalid_delta_v_magnitude_km_s"],
             "source_recommendation" => bad_delta_v_magnitude_source
           } = rows_by_id["bad_delta_v_magnitude"]

    refute Map.has_key?(bad_delta_v_magnitude_source, "delta_v_magnitude_km_s")

    review = OperatorReview.from_maneuver_review_report(report)
    import = CadenceImport.from_maneuver_review_report(report)

    assert Enum.all?(
             review["rows"],
             &(&1["required_operator_action"] == "review_invalid_maneuver_recommendation")
           )

    assert Enum.any?(
             review["rows"],
             &(&1["maneuver_id"] == "bad_success_factor" and
                 &1["rule_id"] == "invalid_maneuver_recommendation_review" and
                 get_in(&1, ["source_policy_decision", "policy_bundle_id"]) ==
                   "maneuver_authority_v1")
           )

    assert Enum.all?(
             import["rows"],
             &(&1["source_review_action"] == "review_invalid_maneuver_recommendation")
           )

    assert Enum.any?(
             import["rows"],
             &(&1["maneuver_id"] == "bad_success_factor" and
                 &1["rule_id"] == "invalid_maneuver_recommendation_review" and
                 get_in(&1, ["source_policy_decision", "policy_bundle_id"]) ==
                   "maneuver_authority_v1")
           )

    assert {:ok, %{"schema_contract" => "maneuver_review_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import)
  end

  test "public facade builds maneuver review reports" do
    report =
      OrbitalDynamics.maneuver_review_report([
        %{
          "id" => "burn",
          "scenario_id" => "leo_1",
          "type" => "impulsive_burn",
          "epoch_s" => 1.0,
          "frame" => "eci_j2000",
          "delta_v_km_s" => [0.0, 0.001, 0.0],
          "maneuver_model" => "impulsive_burns"
        }
      ])

    assert report["maneuver_count"] == 1
    assert [%{"maneuver_id" => "burn"}] = report["rows"]
  end

  test "review gates malformed maneuver recommendation rows instead of raising" do
    report =
      ManeuverReview.report(
        [
          :bad_recommendation,
          %{
            "id" => "missing_delta_v",
            "scenario_id" => "leo_1",
            "type" => "impulsive_burn",
            "epoch_s" => 120.0,
            "frame" => "eci_j2000",
            "maneuver_model" => "impulsive_burns"
          }
        ],
        source: "test.maneuver_recommendations"
      )

    assert %{
             "maneuver_count" => 2,
             "review_required_count" => 2,
             "invalid_maneuver_recommendation_count" => 2,
             "invalid_maneuver_recommendation_ids" => [
               "missing_delta_v",
               "invalid_maneuver:1"
             ]
           } = report

    assert [
             %{
               "maneuver_id" => "missing_delta_v",
               "scenario_id" => "leo_1",
               "required_operator_action" => "review_invalid_maneuver_recommendation",
               "execution_boundary" => "review_only_invalid_maneuver_recommendation",
               "invalid_maneuver_recommendation" => true,
               "invalid_maneuver_recommendation_reasons" => ["invalid_delta_v_km_s"],
               "source_recommendation" => %{"id" => "missing_delta_v"}
             },
             %{
               "maneuver_id" => "invalid_maneuver:1",
               "scenario_id" => "unknown_scenario",
               "required_operator_action" => "review_invalid_maneuver_recommendation",
               "invalid_maneuver_recommendation" => true,
               "invalid_maneuver_recommendation_reasons" => ["invalid_recommendation_shape"],
               "source_recommendation" => %{
                 "invalid_recommendation_shape" => "bad_recommendation"
               }
             }
           ] = report["rows"]

    review = OperatorReview.from_maneuver_review_report(report)
    import = CadenceImport.from_maneuver_review_report(report)

    assert Enum.all?(
             review["rows"],
             &(&1["required_operator_action"] == "review_invalid_maneuver_recommendation")
           )

    assert Enum.all?(
             import["rows"],
             &(&1["source_review_action"] == "review_invalid_maneuver_recommendation")
           )

    assert {:ok, %{"schema_contract" => "maneuver_review_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import)
  end

  test "rejects non-list recommendations" do
    assert_raise ArgumentError, ~r/maneuver recommendations must be a list/, fn ->
      ManeuverReview.report(%{})
    end
  end
end
